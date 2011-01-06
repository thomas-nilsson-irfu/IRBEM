!***************************************************************************************************
! Copyright 2011 T.P. O'Brien
!
! This file is part of IRBEM-LIB.
!
!    IRBEM-LIB is free software: you can redistribute it and/or modify
!    it under the terms of the GNU Lesser General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    IRBEM-LIB is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU Lesser General Public License for more details.
!
!    You should have received a copy of the GNU Lesser General Public License
!    along with IRBEM-LIB.  If not, see <http://www.gnu.org/licenses/>.
!

      REAL*4 FUNCTION GET_BDERIVS_IDL(argc, argv)   ! Called by IDL
      INCLUDE 'wrappers.inc'
c      INTEGER*4 argc, argv(*)                      ! Argc and Argv are integers

       j = loc(argc)                    ! Obtains the number of arguments (argc)
                                       ! Because argc is passed by VALUE.

      call shieldose2(%VAL(argv(1)),%VAL(argv(2)),%VAL(argv(3)),
     &%VAL(argv(4)),%VAL(argv(5)),%VAL(argv(6)),%VAL(argv(7)),
     &%VAL(argv(8)),%VAL(argv(9)),%VAL(argv(10)),%VAL(argv(11)),
     &%VAL(argv(12)),%VAL(argv(13)),%VAL(argv(14)),%VAL(argv(15)),
     &%VAL(argv(16)))

      GET_BDERIVS_IDL = 9.9

      RETURN
      END


      SUBROUTINE GET_Bderivs(ntime,kext,options,sysaxes,dX,
     & iyearsat,
     & idoy,UT,xIN1,xIN2,xIN3,maginput,Bgeo,Bmag,gradBmag,diffB)
C     computes derivatives of B (vector and magnitude)
C     inputs: ntime through maginput have the usual meaning, except dX
C     REAL*8 dX is the step size, in RE for the numerical derivatives (recommend 1E-3?)
C     real*8 Bgeo(3,ntime_max) - components of B in GEO, nT
C     real*8 Bmag(ntime_max) - magnitude of B in nT
C     real*8 gradBmag(3,ntime_max) - gradient of Bmag in GEO, nT/RE
C     real*8 diffB(3,3,ntime_max) - derivatives of Bgeo in GEO, nT/RE
C        diffB(i,j,t) = dB_i/dx_j for point t (t=1 to ntime)

      IMPLICIT NONE
      INCLUDE 'ntime_max.inc'   ! include file created by make, defines ntime_max
      INCLUDE 'variables.inc'
C
      COMMON /magmod/k_ext,k_l,kint

c     declare inputs
      INTEGER*4    ntime,kext,options(5)
      INTEGER*4    sysaxes
      REAL*8       dX
      INTEGER*4    iyearsat(ntime_max)
      integer*4    idoy(ntime_max)
      real*8     UT(ntime_max)
      real*8     xIN1(ntime_max),xIN2(ntime_max),xIN3(ntime_max)
      real*8     maginput(25,ntime_max)

c     declare outputs
      real*8 Bgeo(3,ntime_max) ! components of B in GEO, nT
      real*8 Bmag(ntime_max) ! magnitude of B in nT
      real*8 gradBmag(3,ntime_max) ! gradient of Bmag in GEO, nT/RE
      real*8 diffB(3,3,ntime_max) ! derivatives of Bgeo in GEO, nT/RE

c     declare internal variables
      integer*4  isat
      integer*4  i,j,k_ext,k_l,kint,ifail
      real*8     xGEO(3),xGEOtmp(3)
      real*8     alti,lati,longi
      REAL*8     B1GEO(3),B1,BtmpGEO(3),Btmp
      integer*4 int_field_select, ext_field_select ! functions to call
C
      kint = int_field_select ( options(5) )
      k_ext = ext_field_select ( kext )
c
      CALL INITIZE

      do isat = 1,ntime

         ! initialize outputs to baddata
         Bmag(isat) = baddata
         do i=1,3
            Bgeo(i,isat) = baddata
            gradBmag(i,isat) = baddata
            do j=1,3
               diffB(i,j,isat) = baddata
            enddo
         enddo

         call init_fields(kint,iyearsat(isat),idoy(isat),
     &        ut(isat),options(2))

         call get_coordinates (sysaxes,xIN1(isat),xIN2(isat),xIN3(isat),
     6        alti, lati, longi, xGEO )

         call set_magfield_inputs ( kext, maginput(1,isat), ifail)

         if ( ifail.lt.0 ) then
            goto 1000
         endif
c
         CALL CHAMP(xGEO,B1GEO,B1,Ifail)
         IF ((Ifail.LT.0).or.(B1.eq.baddata)) THEN
            goto 1000
         ENDIF

C copy start point to outputs
         Bmag(isat) = B1
         do i = 1,3
            Bgeo(i,isat) = B1GEO(i)
         enddo

         do j=1,3
C displace in dimension j
            do i = 1,3
               xGEOtmp(i)= xGEO(i)
            enddo
            xGEOtmp(j) = xGEOtmp(j)+dX
            CALL CHAMP(xGEOtmp,BtmpGEO,Btmp,Ifail) ! compute B at displace point
            IF ((Ifail.LT.0).or.(Btmp.eq.baddata)) THEN
               goto 1000
            ENDIF
c     compute derivatives
            gradBmag(j,isat) = (Btmp-B1)/dX
            do i = 1,3
               diffB(i,j,isat) = (BtmpGEO(i)-B1GEO(i))/dX
            enddo
         enddo ! end of j loop

 1000       continue            ! end of isat loop
         enddo

      end


