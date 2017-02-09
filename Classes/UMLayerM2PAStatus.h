//
//  UMLayerM2PAStatus.h
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.



typedef	enum	M2PA_Status
{
    M2PA_STATUS_UNUSED				= -1,
    M2PA_STATUS_OFF					= 100,
    /* SCTP is established but M2PA has not started yet */
    /* requires MTP3 order to start */
    M2PA_STATUS_OOS					= 101,
    /* SCTP is established. MTP3 knows this link now */
    M2PA_STATUS_INITIAL_ALIGNMENT	= 102,
    M2PA_STATUS_ALIGNED_NOT_READY	= 103,
    M2PA_STATUS_ALIGNED_READY		= 104,
    M2PA_STATUS_IS					= 105,
    //	M2PA_STATUS_PROCESSOR_OUTAGE 	= 106,
    
    /* according to Q.703 Page 16 section 7.2 */
    //	M2PA_STATUS_IDLE				=107,
    //	M2PA_STATUS_OUT_OF_ALIGNMENT	=108,
    //	M2PA_STATUS_ALIGNED				=109,
    //	M2PA_STATUS_EMERGENCY			=110,
} M2PA_Status;


typedef enum M2PA_linkstate_message
{
    M2PA_LINKSTATE_ALIGNMENT			= 1,
    /* The Link Status Alignment message replaces the SIO message of
     MTP2. This message is sent to signal the beginning of the alignment
     procedure. The Link Status Alignment message SHOULD NOT be transmitted
     continuously. M2PA MAY send additional Link Status Alignment until it
     receives Link Status Alignment, Link Status Proving Normal, or Link
     Status Proving Emergency from the peer.
     */
    
    M2PA_LINKSTATE_PROVING_NORMAL		= 2,
    M2PA_LINKSTATE_PROVING_EMERGENCY	= 3,
    /*
     The Link Status Proving Normal message replaces the SIN message of
     MTP2. The Link Status Proving Emergency message replaces the SIE
     message of MTP2.
     */
    
    M2PA_LINKSTATE_READY				= 4,
    /* The Link Status Ready message replaces the FISU of MTP2 that is sent
     at the end of the proving period. The Link Status Ready message is
     used to verify that both ends have completed proving. When M2PA starts
     timer T1, it SHALL send a Link Status Ready message to its peer in the
     case where MTP2 would send a FISU after proving is complete. If the
     Link Status Ready message is sent, then M2PA MAY send additional Link
     Status Ready messages while timer T1 is running. These Link Status
     Ready messages are sent on the Link Status stream. */
    M2PA_LINKSTATE_PROCESSOR_OUTAGE			= 5,
    M2PA_LINKSTATE_PROCESSOR_RECOVERED		= 6,
    M2PA_LINKSTATE_BUSY						= 7,
    M2PA_LINKSTATE_BUSY_ENDED				= 8,
    M2PA_LINKSTATE_OUT_OF_SERVICE			= 9,
    /* The Link Status Out of Service message replaces the SIOS message of
     MTP2. Unlike MTP2, the message SHOULD NOT be transmitted
     continuously. After the association is established, M2PA SHALL send a
     Link Status Out of Service message to its peer. Prior to the beginning
     of alignment, M2PA MAY send additional Link Status Out of Service
     messages. */
} M2PA_linkstate_message;


