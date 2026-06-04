/* tc disabled - CBQ removed from kernel headers */
#include "libbb.h"
int tc_main(int argc UNUSED_PARAM, char **argv UNUSED_PARAM) {
    bb_error_msg_and_die("tc not supported in this build");
}
