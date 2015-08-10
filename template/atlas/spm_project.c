#ifndef lint
static char sccsid[]="@(#)spm_project.c	2.2 99/03/19";
#endif
 
/*

spm_project.c
% forms maximium intensity projections - a compiled routine
% FORMAT spm_project(X,L,dims)
% X	-	a matrix of voxel values
% L	- 	a matrix of locations in Talairach et Tournoux (1988) space
% dims  -       assorted dimensions.
%               dims(1:3) - the sizes of the projected rectangles.
%               dims(4:5) - the dimensions of the mip image.
%____________________________________________________________________________
%
% spm_project 'fills in' a matrix (SPM) in the workspace to create
% a maximum intensity projection according to a point list of voxel
% values (V) and their locations (L) in the standard space described
% in the atlas of Talairach & Tournoux (1988).
%
% see also spm_mip.m


*/

/* 
This is a modified version of spm_project that is
intended for use with the SPM adaptation of the
Paxinos Rat-atlas. It is a bit of a hack, and I am
not terribly proud of it, but at least it works fine
with SPM99. Due to its "hack character" there is a
risk that it wont work for newer (or older) versions
of SPM.

Changes are:

New set of D* (width) and C* (center) values
for the three projections.

y-coordinate of transverse slice based on 2*CX
rather than DX (as previously).

New (hacked) criteria for when to map voxels
(i.e. when we are outside the FOV of interest.
These are now based on original coordinates in
relation to size of Paxinos space, rather than
on screen-coordinates as is the case for the 
original spm_project.
In addition, there is a single criterion used
for all projections to ensure consistency across
the projections.

Jesper Andersson, 10/4-02
*/

#include <math.h>
#include <stdio.h>
#include "spm_sys_deps.h"
#include "mex.h"

#define	max(A, B)	((A) > (B) ? (A) : (B))
#define	min(A, B)	((A) < (B) ? (A) : (B))

/* 
Original values suited for Talairach space. 
#define DX 182
#define DY 218
#define DZ 182
#define CX 91
#define CY 127
#define CZ 73
*/

/*
New values suited for Paxinos space.
*/ 
#define DX 189
#define DY 211
#define DZ 175
#define CX 106
#define CY 167
#define CZ 141

#define PX_LX -80
#define PX_UX  80
#define PX_LY -120
#define PX_UY  10
#define PX_LZ -160
#define PX_UZ  60

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	double		*spm,*l,*v,*dim;
	int 		m,m1,n,i,j,k, o;
	int		x,y,z,xdim,ydim,zdim;
	double		q;

	if (nrhs != 3 || nlhs > 1) mexErrMsgTxt("Inappropriate usage.");

	for(k=0; k<nrhs; k++)
		if (!mxIsNumeric(prhs[k]) || mxIsComplex(prhs[k]) ||
			mxIsSparse(prhs[k]) || !mxIsDouble(prhs[k]))
			mexErrMsgTxt("Arguments must be numeric, real, full and double.");

	/* The values */
	n    = mxGetN(prhs[0])*mxGetM(prhs[0]);
	v    = mxGetPr(prhs[0]);

	/* The co-ordinates */
	if ((mxGetN(prhs[1]) != n) || (mxGetM(prhs[1]) != 3))
		mexErrMsgTxt("Incompatible size for locations matrix.");
	l    = mxGetPr(prhs[1]);

	/* Dimension information */
	if (mxGetN(prhs[2])*mxGetM(prhs[2]) != 5)
		mexErrMsgTxt("Incompatible size for dimensions vector.");
	dim  = mxGetPr(prhs[2]);
	xdim = (int) (dim[0] + 0.99);
	ydim = (int) (dim[1] + 0.99);
	zdim = (int) (dim[2] + 0.99);
	m    = (int) (dim[3]);
	m1   = (int) (dim[4]);

	plhs[0] = mxCreateDoubleMatrix(m,m1,mxREAL);
	spm     = mxGetPr(plhs[0]);

	if (m == DY+DX && m1 == DZ+DX) /* MNI Space */
	{
	        /* go though point list */
		for (i = 0; i < n; i++)
		{
			x = (int)rint(l[i*3 + 0]) + CX;
			y = (int)rint(l[i*3 + 1]) + CY;
			z = (int)rint(l[i*3 + 2]) + CZ;

/* Old version 		if (x-xdim/2>=0 && x+xdim/2<DX && y-ydim/2>=0 && y+ydim/2<DY) *//* transverse */
                        if (l[i*3+0]>PX_LX && l[i*3+0]<PX_UX && l[i*3+1]>PX_LZ && l[i*3+1]<PX_UZ && l[i*3+2]>PX_LY && l[i*3+2]<PX_UY)
			{
				q = v[i];
				for (j = -ydim/2; j <= ydim/2; j++)
					for (k = -xdim/2; k <= xdim/2; k++)
					{
						o = j + y - 2 + (k + 2*CX - x - 2)*m;
/* Old version.                                 o = j + y - 2 + (k + DX - x - 2)*m; */
						if (spm[o]<q) spm[o] = q;
					}

/* Old version		if (z-zdim/2>=0 && z+zdim/2<DZ && y-ydim/2>=0 && y+ydim/2<DY) *//* sagittal */

				q = v[i];
				for (j = -ydim/2; j <= ydim/2; j++)
					for (k = -zdim/2; k <= zdim/2; k++)
					{
						o = j + y - 2 + (DX + k + z - 2)*m;
						if (spm[o]<q) spm[o] = q;
					}

/* Old version		if (x-xdim/2>=0 && x+xdim/2<DX && z-zdim/2>=0 && z+zdim/2<DZ) *//* coronal */
				q = v[i];
				for (j = -xdim/2; j <= xdim/2; j++)
					for (k = -zdim/2; k <= zdim/2; k++)
					{
						o = DY + j + x - 2 + (DX + k + z - 2)*m;
						if (spm[o]<q) spm[o] = q;
					}
			}
		}
        }
    else if (m == 360 && m1 == 352) /* old code for the old MIP matrix */
    {
	for (i = 0; i < n; i++) {
	    x = (int) l[i*3 + 0];
	    y = (int) l[i*3 + 1];
	    z = (int) l[i*3 + 2];
    
	    /* transverse */
	    q = max(v[i], spm[(124 + y) + (104 - x)*m]);
	    for (j = 0; j < ydim; j++) {
		    for (k = 0; k < xdim; k++) {
				spm[124 + j + y + (104 + k - x)*m] = q;
		    }
	    }
    
	    /* sagittal */
	    q = max(v[i], spm[(124 + y) + (240 + z)*m]);
	    for (j = 0; j < ydim; j++) {
		    for (k = 0; k < zdim; k++) {
				spm[124 + j + y + (238 + k + z)*m] = q;
		    }
	    }
    
	    /* coronal */
	    q = max(v[i], spm[(276 + x) + (240 + z)*m]);
	    for (j = 0; j < xdim; j++) {
		    for (k = 0; k < zdim; k++) {
				spm[276 + j + x + (238 + k + z)*m] = q;
		    }
	    }
	}
    }
    else 
	    mexErrMsgTxt("Wrong sized MIP matrix");
}
