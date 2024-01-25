/**
 * Copyright (C) 2013 Quan Wang <wangq10@rpi.edu>,
 * Signal Analysis and Machine Perception Laboratory,
 * Department of Electrical, Computer, and Systems Engineering,
 * Rensselaer Polytechnic Institute, Troy, NY 12180, USA
 */

/**
 * This is the C/MEX code of dynamic time warping of two signals
 *
 * compile:
 *     mex dtw_c.c
 *
 * usage:
 *     d=dtw_c(s,t)  or  d=dtw_c(s,t,w)
 *     where s is signal 1, t is signal 2, w is window parameter
 */

#include "mex.h"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

double vectorDistance(double *s, double *t, int ns, int nt, int i, int j)
{
    double result=0;
   
    result=sqrt((s[i]-t[j])*(s[i]-t[j]));
    return result;
}

void dtw_SP(double *s, double *t, double *D, int w, int ns, int nt)
{
//     double d=0;
    int sizediff=ns-nt>0 ? ns-nt : nt-ns;
//     double ** D;
    int i,j;
    int j1,j2;
    double cost,temp;
    
    // printf("ns=%d, nt=%d, w=%d, s[0]=%f, t[0]=%f\n",ns,nt,w,s[0],t[0]);
    
    if(w!=-1 && w<sizediff) w=sizediff; // adapt window size
    
    // dynamic programming
    for(i=1;i<=ns;i++)
    {
        if(w==-1)
        {
            j1=1;
            j2=nt;
        }
        else
        {
            j1= i-w>1 ? i-w : 1;
            j2= i+w<nt ? i+w : nt;
        }
        
        for(j=j1;j<=j2;j++)
        {
            //cost=vectorDistance(s,t,ns,nt,i,j);
            cost=sqrt((s[i-1]-t[j-1])*(s[i-1]-t[j-1]));
            temp=D[(i-1)*(nt+1)+j];
            
            if(D[i*(nt+1)+j-1]!=-1)
            {
                if(temp==-1 || D[i*(nt+1)+j-1]<temp)
                    temp=D[i*(nt+1)+j-1];
            }
            if(D[(i-1)*(nt+1)+j-1]!=-1)
            {
                if(temp==-1 || D[(i-1)*(nt+1)+j-1]<temp)
                    temp=D[(i-1)*(nt+1)+j-1];
            }
            D[i*(nt+1)+j]=cost+temp;
        }
    }
    
}

/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[])
{
    double *s,*t,*D;
    int w,i,j;
    int ns,nt;
    
    /*  check for proper number of arguments */
    if(nrhs!=2&&nrhs!=3)
    {
        mexErrMsgIdAndTxt( "MATLAB:dtw_c:invalidNumInputs",
                "Two or three inputs required.");
    }
    if(nlhs>1)
    {
        mexErrMsgIdAndTxt( "MATLAB:dtw_c:invalidNumOutputs",
                "dtw_c: One output required.");
    }
    
    /* check to make sure w is a scalar */
    if(nrhs==2)
    {
        w=-1;
    }
    else if(nrhs==3)
    {
        if( !mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) ||
                mxGetN(prhs[2])*mxGetM(prhs[2])!=1 )
        {
            mexErrMsgIdAndTxt( "MATLAB:dtw_c:wNotScalar",
                    "dtw_c: Input w must be a scalar.");
        }
        
        /*  get the scalar input w */
        w = (int) mxGetScalar(prhs[2]);
    }
    
    
    /*  create a pointer to the input matrix s */
    s = mxGetPr(prhs[0]);
    
    /*  create a pointer to the input matrix t */
    t = mxGetPr(prhs[1]);
    
    /*  get the dimensions of the matrix input s */
    ns = mxGetM(prhs[0]);
    
    
    /*  get the dimensions of the matrix input t */
    nt = mxGetM(prhs[1]);
    
    
    /*  set the output pointer to the output matrix */
    plhs[0] = mxCreateDoubleMatrix(1+ns, 1+nt, mxREAL);
    
    /*  create a C pointer to a copy of the output matrix */
    D = mxGetPr(plhs[0]);
    
    for (i=0;i<=ns;i++){
        for (j=0;j<=nt;j++){
            D[i*(nt+1)+j]=1000000;
        }    
    }        
	D[0]=0;
    /*  call the C subroutine */
    dtw_SP(s,t,D,w,ns,nt);
    
    return;
}
