#include"hpmq.h"

#include<cstdio>
#include<cstdlib>
#include<cassert>
#define F(i,l,r) for(int i=l;i<r;++i)

static unsigned int tot;

void Data::add_eq(const Data &a){
	if(a.empty())return;
	if(empty())return void(*this=a);
	++tot;
	F(i,0,2)x[i]+=a.x[i];
}
void Data::add(const Data &a,const Data &b){
	if(a.empty())return void(*this=b);
	if(b.empty())return void(*this=a);
	++tot;
	F(i,0,2)x[i]=a.x[i]+b.x[i];
}
void Data::clr(){
	F(i,0,2)x[i]=0;
}
void Data::read(){
	F(i,0,2)assert(scanf("%u",x+i)==1);
}
void Data::print()const{
	printf("%u %u\n",x[0],x[1]);
}
bool Data::empty()const{
	F(i,0,2)if(x[i])return 0;
	return 1;
}

void Operation::apply(Data &w)const{
	if(w.empty())return;
	if(empty())return;
	++tot;
	Data z;
	F(i,0,2)F(k,0,2)z.x[i]+=a[i][k]*w.x[k];
	w=z;
}
void Operation::apply(Operation &w)const{
	if(empty())return;
	if(w.empty())return void(w=*this);
	++tot;
	Operation z;
	F(i,0,2)F(k,0,2)F(j,0,2)z.a[i][j]+=a[i][k]*w.a[k][j];
	w=z;
}
void Operation::clr(){
	F(i,0,2)F(j,0,2)a[i][j]=0;
}
void Operation::read(){
	F(i,0,2)F(j,0,2)assert(scanf("%u",a[i]+j)==1);
}
bool Operation::empty()const{
	F(i,0,2)F(j,0,2)if(a[i][j])return 0;
	return 1;
}
static const int N=2e5+7,M=1e4+7;
static int x[N],y[N],a[M],b[M],c[M];
static Data d[N];
static Operation o[M];

int read(int L,int R){
	int x;
	assert(scanf("%d",&x)==1);
	assert(L<=x&&x<=R);
	return x;
}

int main(){
	int n=read(1,2e5);
	F(i,0,n){
		x[i]=read(-1e6,1e6);
		y[i]=read(-1e6,1e6);
		d[i].read();
	}
	int m=read(1,1e4);
	F(i,0,m){
		a[i]=read(-1e3,1e3);
		b[i]=read(-1e3,1e3);
		c[i]=read(-1e6,1e6);
		o[i].read();
	}
	solve(n,m,x,y,d,a,b,c,o);
	printf("%u\n",tot);
	return 0;
}
