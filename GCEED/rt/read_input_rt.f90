!
!  Copyright 2017 SALMON developers
!
!  Licensed under the Apache License, Version 2.0 (the "License");
!  you may not use this file except in compliance with the License.
!  You may obtain a copy of the License at
!
!      http://www.apache.org/licenses/LICENSE-2.0
!
!  Unless required by applicable law or agreed to in writing, software
!  distributed under the License is distributed on an "AS IS" BASIS,
!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!  See the License for the specific language governing permissions and
!  limitations under the License.
!
subroutine read_input_rt(IC_rt,OC_rt,Ntime)
use salmon_parallel, only: nproc_id_global, nproc_group_global, nproc_size_global
use salmon_communication, only: comm_is_root
use mpi, only: mpi_integer, mpi_double_precision, mpi_character
use inputoutput
use scf_data
use new_world_sub
implicit none
integer :: ii
integer :: IC_rt,OC_rt
integer :: Ntime
integer :: inml_group_fundamental, &
         & inml_group_parallel, &
         & inml_group_hartree, &
         & inml_group_file, &
         & inml_group_others
integer :: ierr


namelist / group_fundamental / idisnum, iwrite_projection, &
                               itwproj, iwrite_projnum, itcalc_ene
namelist / group_parallel /  isequential, imesh_s_all, iflag_comm_rho
namelist / group_hartree / Hconv, lmax_MEO
namelist / group_file / IC,IC_rt,OC_rt
namelist / group_others / iparaway_ob,num_projection,iwrite_projection_ob,iwrite_projection_k,  &
                          filename_pot, &
    & iwrite_external,iflag_dip2,iflag_intelectron,num_dip2, dip2boundary, dip2center,& 
    & iflag_fourier_omega, num_fourier_omega, fourier_omega, itotNtime2, &
    & iwdenoption,iwdenstep, numfile_movie, iflag_Estatic

if(comm_is_root(nproc_id_global))then
   open(fh_namelist, file='.namelist.tmp', status='old')
end if

!===== namelist for group_fundamental =====
icalcforce=0
iflag_md=0
idisnum(1)=1
idisnum(2)=2
iwrite_projection=0
iwrite_projnum=0
itwproj=-1
itcalc_ene=1
if(comm_is_root(nproc_id_global))then
  read(fh_namelist,NML=group_fundamental, iostat=inml_group_fundamental)
  rewind(fh_namelist)
end if

select case(use_force)
case('y')
  icalcforce = 1
case('n')
  icalcforce = 0
case default
  stop 'invald icalcforce'
end select

select case(use_ehrenfest_md)
case('y')
  iflag_md = 1
case('n')
  iflag_md = 0
case default
  stop 'invald iflag_md'
end select

call MPI_Bcast(Nenergy,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(N_hamil,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(icalcforce,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iflag_md,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(idisnum,2,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iwrite_projection,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iwrite_projnum,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(itwproj,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(itcalc_ene,1,MPI_INTEGER,0,nproc_group_global,ierr)

allocate(wtk(1))
wtk(:)=1.d0

if(iwrite_projection==1.and.itwproj==-1)then
  write(*,*) "Please specify itwproj when iwrite_projection=1."
  stop
end if

!===== namelist for group_parallel =====
!nproc_ob=0
nproc_Mxin(1:3)=0
nproc_Mxin_s(1:3)=0
isequential=2
imesh_s_all=1
iflag_comm_rho=1
if(comm_is_root(nproc_id_global))then
  read(fh_namelist,NML=group_parallel, iostat=inml_group_parallel)
  rewind(fh_namelist)
  if(isequential<=0.or.isequential>=3)then
    write(*,*) "isequential must be equal to 1 or 2."
    stop
  end if
end if

nproc_Mxin = nproc_domain
nproc_Mxin_s = nproc_domain_s

call MPI_Bcast(nproc_ob,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(nproc_Mxin,3,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(nproc_Mxin_s,3,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(isequential,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(num_datafiles_IN,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(num_datafiles_OUT,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(imesh_s_all,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iflag_comm_rho,1,MPI_INTEGER,0,nproc_group_global,ierr)
if(comm_is_root(nproc_id_global).and.nproc_ob==0)then
  write(*,*) "set nproc_ob."
  stop
else if(comm_is_root(nproc_id_global).and.nproc_Mxin(1)*nproc_Mxin(2)*nproc_Mxin(3)==0)then
  write(*,*) "set nproc_Mxin."
  stop
else if(comm_is_root(nproc_id_global).and.nproc_Mxin_s(1)*nproc_Mxin_s(2)*nproc_Mxin_s(3)==0)then
  write(*,*) "set nproc_Mxin_s."
  stop
end if
call check_numcpu

nproc_Mxin_mul=nproc_Mxin(1)*nproc_Mxin(2)*nproc_Mxin(3)
nproc_Mxin_mul_s_dm=nproc_Mxin_s_dm(1)*nproc_Mxin_s_dm(2)*nproc_Mxin_s_dm(3)

!===== namelist for group_propagation =====
!dt=0.d0
Ntime=nt
!if(comm_is_root(nproc_id_global))then
!  read(fh_namelist,NML=group_propagation)
!  rewind(fh_namelist)
!end if
call MPI_Bcast(dt,1,MPI_DOUBLE_PRECISION,0,nproc_group_global,ierr)
call MPI_Bcast(Ntime,1,MPI_INTEGER,0,nproc_group_global,ierr)
if(dt<=1.d-10)then
  write(*,*) "please set dt."
  stop
end if
if(Ntime==0)then
  write(*,*) "please set Ntime."
  stop
end if

!===== namelist for group_hartree =====
! Convergence criterion, ||Vh(i)-Vh(i-1)||**2/(# of grids), 1.d-15 a.u. = 1.10d-13 eV**2*AA**3
Hconv=1.d-15*uenergy_from_au**2*ulength_from_au**3
lmax_MEO=4
if(comm_is_root(nproc_id_global))then
  read(fh_namelist,NML=group_hartree, iostat=inml_group_hartree ) 
  rewind(fh_namelist)
  if(MEO<=0.or.MEO>=4)then
    write(*,*) "MEO must be equal to 1 or 2 or 3."
    stop
  end if
  if(MEO==3.and.(num_pole_xyz(1)==-1.or.num_pole_xyz(2)==-1.or.num_pole_xyz(3)==-1))then
    write(*,*) "num_pole_xyz must be set when MEO=3."
    stop
  end if
end if
call MPI_Bcast(Hconv,1,MPI_DOUBLE_PRECISION,0,nproc_group_global,ierr)
Hconv  = Hconv*uenergy_to_au**2*ulength_to_au**3
call MPI_Bcast(MEO,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(num_pole_xyz,3,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(lmax_MEO,1,MPI_INTEGER,0,nproc_group_global,ierr)

num_pole=num_pole_xyz(1)*num_pole_xyz(2)*num_pole_xyz(3)

!===== namelist for group_file =====
IC=1
IC_rt=0
OC_rt=0
if(comm_is_root(nproc_id_global))then
  read(fh_namelist,NML=group_file, iostat=inml_group_file)
  rewind(fh_namelist)
end if
call MPI_Bcast(IC,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(IC_rt,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(OC_rt,1,MPI_INTEGER,0,nproc_group_global,ierr)

if(IC==3.and.num_datafiles_IN/=nproc_size_global)then
  if(comm_is_root(nproc_id_global))then
    write(*,*) "num_datafiles_IN is set to nproc."
  end if
  num_datafiles_IN=nproc_size_global
end if

!===== namelist for group_extfield =====
if(ae_shape1 == 'impulse')then
  ikind_eext = 0
else
  ikind_eext = 1
end if

Fst = e_impulse
romega = omega1
pulse_T = pulse_tw1
rlaser_I = rlaser_int1

if(epdir_im1(1)**2+epdir_im1(2)**2+epdir_im1(3)**2+ &
   epdir_im2(1)**2+epdir_im2(2)**2+epdir_im2(3)**2>=1.d-12)then
  circular='y'
else
  circular='n'
end if

!===== namelist for group_others =====

iparaway_ob=2
num_projection=1
do ii=1,200
  iwrite_projection_ob(ii)=ii
  iwrite_projection_k(ii)=1
end do
filename_pot='pot'
iwrite_external=0
iflag_dip2=0
iflag_intelectron=0
num_dip2=1
dip2boundary(:)=0.d0
dip2center(:)=0.d0
iflag_fourier_omega=0
num_fourier_omega=1
fourier_omega(:)=0.d0
itotNtime2=Ntime
iwdenoption=0
iwdenstep=0
numfile_movie=1
iflag_Estatic=0
if(comm_is_root(nproc_id_global))then
  read(fh_namelist,NML=group_others, iostat=inml_group_others)
  rewind(fh_namelist)
end if
call MPI_Bcast(iparaway_ob,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(num_projection,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iwrite_projection_ob,200,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iwrite_projection_k,200,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(filename_pot,100,MPI_CHARACTER,0,nproc_group_global,ierr)
call MPI_Bcast(iwrite_external,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iflag_dip2,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iflag_intelectron,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(num_dip2,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(dip2boundary,100,MPI_DOUBLE_PRECISION,0,nproc_group_global,ierr)
dip2boundary = dip2boundary*ulength_to_au
call MPI_Bcast(dip2center,100,MPI_DOUBLE_PRECISION,0,nproc_group_global,ierr)
dip2center = dip2center*ulength_to_au
call MPI_Bcast(iflag_fourier_omega,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(num_fourier_omega,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(fourier_omega,200,MPI_DOUBLE_PRECISION,0,nproc_group_global,ierr)
fourier_omega = fourier_omega*uenergy_to_au
call MPI_Bcast(itotNtime2,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iwdenoption,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iwdenstep,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(numfile_movie,1,MPI_INTEGER,0,nproc_group_global,ierr)
call MPI_Bcast(iflag_Estatic,1,MPI_INTEGER,0,nproc_group_global,ierr)

if(iflag_dip2==0)then
  allocate(rto(1))
  allocate(idip2int(1))
else if(iflag_dip2==1)then
  allocate(rto(1:num_dip2-1))
  allocate(idip2int(1:num_dip2-1))

!  dip2center(:)=dip2center(:)/a_B
end if

if(comm_is_root(nproc_id_global))then
  if(iwdenoption/=0.and.iwdenoption/=1)then
    write(*,*)  'iwdenoption must be equal to 0 or 1.'
    stop
  end if
end if
if(iwdenoption==0)then
  iwdenstep=0
end if

if(comm_is_root(nproc_id_global))close(fh_namelist)

end subroutine read_input_rt
