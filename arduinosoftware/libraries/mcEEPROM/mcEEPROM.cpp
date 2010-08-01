/*
 * mcEEPROM.cpp
 *
 *  Created on: Jul 27, 2010
 *      Author: Jim Gallt
 *      Copyright (C) 2010 MLG Properties, LLC
 *      All rights reserved.
 *
 *      Version 20100731
 */


// fixme  flakey behavior when ptr approaches 128 ??

#include <mcEEPROM.h>

// --------------------------
mcEEPROM::mcEEPROM( uint8_t select ) {
	chip_addr = select;
	Wire.begin();
}

// -------------------------- read array of bytes
uint16_t mcEEPROM::read( uint16_t ptr, uint8_t* barray, uint16_t count ) {
//	Serial.println( count, DEC );
	if( count > MAX_COUNT )
		return 0;
	uint16_t i, j, k, n;
	k = 0;
	for( i = 0; i < count; i += BUFFER_SIZE ){
		DELAY;
		Wire.beginTransmission( chip_addr );
		Serial.print( (uint8_t)( ptr >> 8 ), HEX ); Serial.print(",");
		Serial.print( (uint8_t)( ptr >> 0 ), HEX ); // Serial.print(",");
		Serial.println();
		Wire.send( (uint8_t)( ptr >> 8 ) ); // MSB of pointer
		Wire.send( (uint8_t)( ptr >> 0 ) ) ; // LSB of pointer)
		Wire.endTransmission();
		Wire.requestFrom( chip_addr, (uint8_t)BUFFER_SIZE );
		n = Wire.available();
//		Serial.print("n = "); Serial.println( n, DEC );
		for( j = 0; (j < n && k < count ); j++ ) {
			barray[k] = Wire.receive();
			// Serial.println(barray[k], HEX );
			++k;
		}
		ptr += BUFFER_SIZE;
	}
	return k;
}

// ------------------------------- read string
uint16_t mcEEPROM::read( uint16_t ptr, char str[] ) {
	uint16_t i, j, k, n;
	uint8_t max = 0xFF;
	k = 0;
	uint8_t done = 0;
	for( i = 0; i < max && done == 0; i += BUFFER_SIZE ){
		DELAY;
		Wire.beginTransmission( chip_addr );
		Wire.send( (uint8_t)( ptr >> 8 ) ); // MSB of pointer
		Wire.send( (uint8_t)( ptr >> 0 ) ) ; // LSB of pointer)
		Wire.endTransmission();
		Wire.requestFrom( chip_addr, (uint8_t)BUFFER_SIZE );
		n = Wire.available();
		for( j = 0; (j < n && k < max ); j++ ) {
			uint8_t b;
			b = Wire.receive();
			str[k++] = (char)b;
			if( (char)b == '\0' ) {
				done = 1;
				break;
			}
		}
		ptr += BUFFER_SIZE;
	}
	return k;
}

// --------------------------- read float
uint16_t mcEEPROM::read( uint16_t ptr, float f[] ) {
	return read( ptr, (uint8_t*)f, sizeof( float ) );
}

// --------------------------- read integer
uint16_t mcEEPROM::read( uint16_t ptr, int m[] ) {
	return read( ptr, (uint8_t*)m, sizeof( int ));
}

/*
// -------------------------- write array of bytes
uint16_t mcEEPROM::write( uint16_t ptr, uint8_t* barray, uint16_t count ) {
//	Serial.println( count, DEC );
	if( count > MAX_COUNT )
		return 0;
	uint16_t i;

	for( i = 0; i < count; i++ ){  // fixme try and write more than 1 byte at a time
		// Serial.println( barray[i], HEX );
		DELAY;
		Wire.beginTransmission( chip_addr );
		Wire.send( (uint8_t)( ptr >> 8 ) ); // MSB of pointer
		Wire.send( (uint8_t)( ptr >> 0 ) ) ; // LSB of pointer)
		Wire.send( barray[i] );
		Wire.endTransmission();
		++ptr;
	}
	return i;
}
*/

// -------------------------- write array of bytes
uint16_t mcEEPROM::write( uint16_t ptr, uint8_t* barray, uint16_t count ) {
//	Serial.println( count, DEC );
	if( count > MAX_COUNT )
		return 0;
	uint16_t i,j,k;
	k = 0;
	for( i = 0; i < count; i+= BUFFER_SIZE ){  //
		// Serial.println( barray[i], HEX );
		DELAY;
		Wire.beginTransmission( chip_addr );
		Serial.print( (uint8_t)( ptr >> 8 ), HEX ); Serial.print(",");
		Serial.print( (uint8_t)( ptr >> 0 ), HEX ); // Serial.print(",");
		Serial.println();
		Wire.send( (uint8_t)( ptr >> 8 ) ); // MSB of pointer
		Wire.send( (uint8_t)( ptr >> 0 ) ) ; // LSB of pointer)
		// next, fill up the remaining buffer with data
		for( j = 0; j < BUFFER_SIZE - 2 && k < count; j++, k++ ) {
			Wire.send( barray[k] );
//			Serial.print( k, DEC ); Serial.print(","); Serial.println( barray[k], BYTE);
		}
		Wire.endTransmission(); // buffer is written by this call
//		Serial.println("End transmission.");
		ptr += BUFFER_SIZE - 2;
	}
	return k;
}

// ----------------------------------- write string
uint16_t mcEEPROM::write( uint16_t ptr, char str[] ) {
	int len = strlen ( str ) + 1;
	return write( ptr, (uint8_t*)str, len );
}

// --------------------------------------- write float
uint16_t mcEEPROM::write( uint16_t ptr, float f[] ) {
	return write( ptr, (uint8_t*)f, sizeof( float ) );
}

// ---------------------------------------- write integer
uint16_t mcEEPROM::write( uint16_t ptr, int m[] ) {
	return write( ptr, (uint8_t*)m, sizeof( int ) );
}




