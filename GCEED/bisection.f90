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

subroutine bisection(xx,inode,iak)
use read_pslfile_sub
use allocate_psl_sub
implicit none
integer :: inode
integer :: iak
integer :: imin,imax
real(8) :: xx

imin=0
imax=Nr
do while (imax-imin>1)
  inode=(imin+imax)/2
  if(xx>rad_psl(inode,iak))then
    imin=inode
  else
    imax=inode
  end if
end do
inode=imin

end subroutine bisection
