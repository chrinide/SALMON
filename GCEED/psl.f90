! Copyright 2017 Katsuyuki Nobusada, Masashi Noda, Kazuya Ishimura, Kenji Iida, Maiku Yamaguchi
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.

SUBROUTINE init_ps
!$ use omp_lib
use scf_data
use allocate_psl_sub
implicit none

if(iSCFRT==1)then
  if(myrank.eq.0)then
    print *,"----------------------------------- init_ps"
  end if
end if

call storevpp

Mps=0
call calcJxyz
call calcuV
call calcVpsl
call calcJxyz2nd

return

END SUBROUTINE init_ps
