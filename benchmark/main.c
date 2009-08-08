/* 
 * Copyright (C) 2009 Chris McClelland
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *  
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include "libusb.h"
#ifdef WIN32
#include <Windows.h>
#else
#include <sys/time.h>
#endif
#include "dump.h"

#define VID 0x04b4
#define PID 0x8613

#define RANDOM_DATA
#define BUFFER_SIZE (1024*1024)

int main(void) {
	UsbDeviceHandle *deviceHandle;
	int returnCode;
	long long startTime;
	long long endTime;
	double totalTime, speed;

	usbInitialise();
	returnCode = usbOpenDevice(VID, PID, 1, 0, 0, &deviceHandle);
	if ( returnCode ) {
		fprintf(stderr, "%s\n", usbStrError());
	}
	if ( deviceHandle ) {
		unsigned char *dat;
		unsigned short checksum = 0x0000;
		int i;
		FILE *file;
		#ifdef WIN32
			LARGE_INTEGER tvStart, tvEnd, freq;
			DWORD_PTR mask = 1;
			SetThreadAffinityMask(GetCurrentThread(), mask);
			QueryPerformanceFrequency(&freq);
		#else
			struct timeval tvStart, tvEnd;
		#endif
		file = fopen("random.dat", "rb");
		//file = fopen("/dev/urandom", "rb");
		if ( file ) {
			dat = malloc(BUFFER_SIZE);
			if ( !dat ) {
				printf("Unable to allocate buffer\n");
				exit(1);
			}
			#ifdef RANDOM_DATA
				returnCode = fread(dat, 1, BUFFER_SIZE, file);
				if ( returnCode != BUFFER_SIZE ) {
					printf("The file does not contain sufficient data; I need at least %d bytes\n", BUFFER_SIZE);
					exit(1);
				}
				fclose(file);
			#else
				for ( i = 0; i < BUFFER_SIZE; i++ ) {
					dat[i] = 0x00;
				}
			#endif
			for ( i = 0; i < BUFFER_SIZE; i++  ) {
				checksum += dat[i];
			}
			//printf("Out buffer:\n");
			//dump(0x00000000, dat, BUFFER_SIZE);
			#ifdef WIN32
				QueryPerformanceCounter(&tvStart);
				returnCode = usb_bulk_write(deviceHandle, USB_ENDPOINT_OUT | 6, (char*)dat, BUFFER_SIZE, 5000);
				QueryPerformanceCounter(&tvEnd);
			#else
				gettimeofday(&tvStart, NULL);
				returnCode = usb_bulk_write(deviceHandle, USB_ENDPOINT_OUT | 6, (char*)dat, BUFFER_SIZE, 5000);
				gettimeofday(&tvEnd, NULL);
			#endif
			if ( returnCode != BUFFER_SIZE ) {
				printf("usb_bulk_write() returned %d\n", returnCode);
				exit(1);
			}
			#ifdef GET_IN
				returnCode = usb_bulk_read(deviceHandle, USB_ENDPOINT_IN | 2, (char*)buf, BUFFER_SIZE, 5000);
				if ( returnCode != BUFFER_SIZE ) {
					printf("usb_bulk_read() returned %d\n", returnCode);
					exit(1);
				}
				printf("\nIn buffer:\n");
				dump(0x00000000, inBuf, BUFFER_SIZE);
			#endif
			#ifdef WIN32
				totalTime = tvEnd.QuadPart - tvStart.QuadPart;
				totalTime /= freq.QuadPart;
				speed = (double)BUFFER_SIZE / (1024*1024*totalTime);
			#else
				startTime = tvStart.tv_sec;
				startTime *= 1000000;
				startTime += tvStart.tv_usec;
				endTime = tvEnd.tv_sec;
				endTime *= 1000000;
				endTime += tvEnd.tv_usec;
				totalTime = endTime - startTime;
				totalTime /= 1000000;  // convert from uS to S.
				speed = (double)BUFFER_SIZE / (1024*1024*totalTime);
			#endif
			printf("%f MB/s\nchecksum=0x%04X\n", speed, checksum);
			free(dat);
		} else {
			perror("File error: ");
		}

		usb_close(deviceHandle);
	}

	return 0;
}
