//user.pde
/*
contains the stuff that the user may want to change

*/

int MIN_TEMP = 0; // degrees
int MAX_TEMP = 550;  // degrees (or 10 * degF per minute)

int MAX_TIME = 1020; // seconds
int BUFFER_SIZE = 3000; //define large size for buffers, so they don't overflow even if after max time

int TEMP_INCR = 20;  // degrees
