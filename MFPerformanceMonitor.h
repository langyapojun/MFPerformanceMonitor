//
//  MFPerformanceMonitor.h
//  MakeFriends
//
//  Created by Vic on 26/8/2016.
//
//

#ifndef MFPerformanceMonitor_h
#define MFPerformanceMonitor_h

#ifdef MF_PERFORMANCE_MONITOR_ENABLED
#define _INTERNAL_MFPM_ENABLED MF_PERFORMANCE_MONITOR_ENABLED
#else
#define _INTERNAL_MFPM_ENABLED !RELEASE
#endif


#endif /* MFPerformanceMonitor_h */
