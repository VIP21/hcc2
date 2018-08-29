#include <stdio.h>
#include <omp.h>

int main()
{
    printf ("String on   host: %s\n", "12345_ABCDEFGabcdegf?!");
#pragma omp target
  {
    char *str = "12345_ABCDEFGabcdegf?!";
    char *fmt = "String on device: %s\n";
    printf ("String on device: %s\n", "12345_ABCDEFGabcdegf?!");
    printf ("String on device: %s\n", str);
    printf (fmt, str);
  }

  return 0;
}
