/* Appends user's and his groups' IDs to
 * /etc/subuid and /etc/subgid, respectivelly,
 * if not present already.
 * Used for setting up rootless docker in slurm.
 *
 * Why does this exist when pam-create-docker-subids.sh
 * does exactly the same thing?
 * - I'm glad you ask! Slurm jobs don't go through PAM
 *   when executing a user's request. This is supposed
 *   to be a suid binary called from a script setting
 *   up docker. This is the only part requiring root
 *   priviledges.
 *
 * If you need root priviledges, why don't you just
 * put a script in slurm.conf's Prolog?
 * - I'm not sure if the Prolog program runs as root.
 *   The manpage slurm.conf(5) only mentions root in
 *   Epilog (after jobs are run). Plus, I think it's
 *   overkill and perhaps risky(?) to run something
 *   in every slurm job when it isn't necessary for
 *   all cases.
 *
 * Why C?
 * - Why not?
 *
 * 2021-03 marcelo.santos
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <sys/file.h>
#include <pwd.h>

#define SUBUID_FILE   "/etc/subuid"
#define SUBGID_FILE   "/etc/subgid"
#define RANGE         65536
#define DEFAULT_START 100000

// UIDs from real users need only 21 bits to be represented (log(1999999,2) < 21)
#define UID_SIGNIFICANT_BITS 21

// UID bits that are never used in IST IDs
#define UID_HIGH_BITS (UINT32_MAX << UID_SIGNIFICANT_BITS)


void fail(const char *msg) {
	fprintf(stderr, "[subidappend] %s\n", msg);
	exit(1);
}

void append(int uid, char *filename) {
	FILE *f = fopen(filename, "a+");
	if (!f) { fail(strerror(errno)); }

	uint32_t start = uid << 16;

	// NOTE: this temporary variable MUST stay. sth sth weird C standard thing makes
	// the comparison always fail if we inline the expression in the if statement condition.
	uint32_t start_high_bits = start & UID_HIGH_BITS;
	if (start_high_bits == 0) {
		// sub UIDs can collide with regulard UIDs
		// this will set all those bits to 1
		start |= UID_HIGH_BITS;
	}

	uint32_t line_uid;
	uint32_t line_start;
	int line_range;

	int ret;
	while ((ret = fscanf(f, "%u:%u:%u\n", &line_uid, &line_start, &line_range)) != EOF) {
		if (ret != 3) {
			fail("Bad file reading");
		}

		// Name already present
		if (uid == line_uid) {
			fclose(f);
			return;
		}

		if (start == line_start) {
			fail("sub id collision with existing entry");
		}
	}

	fprintf(f, "%u:%u:%u\n", uid, start, RANGE);

	fclose(f);
}

static int lock_fd;
void release_flock(void) {
	flock(lock_fd, LOCK_UN);
}

int main() {
	// getlogin() doesn't return the real username
	char *login_str = getenv("PAM_USER");

	if (!login_str) {
		fail("Failed getting login username");
	}

	struct passwd *user = getpwnam(login_str);
	if (user == NULL) {
		fail("Failed getting user information");
	}
	uint32_t login = user->pw_uid;

    lock_fd = open("/etc/subuid", O_RDONLY);
	if (lock_fd == -1) {
		fail("could not open /etc/subuid");
	}
	if (flock(lock_fd, LOCK_EX) != 0) {
		fail("could not acquire flock on /etc/subuid");
	}
	if (atexit(release_flock) != 0) {
		release_flock();
		fail("could not register lock releaser exit handler");
	}

	append(login, SUBUID_FILE);
	append(login, SUBGID_FILE);

	return 0;
}
