#include"data.h"

#include<cstdio>
#include<cstdlib>
#include<cassert>
#define F(i,l,r) for(int i=l;i<r;++i)

static unsigned long long tot;

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
	F(i,0,2)F(j,0,2)z.a[i][j]=0;
	F(i,0,2)F(k,0,2)F(j,0,2)z.a[i][j]+=a[i][k]*w.a[k][j];
	w=z;
}
void Operation::clr(){
	F(i,0,2)F(j,0,2)a[i][j]=(i!=j);
}
void Operation::read(){
	F(i,0,2)F(j,0,2)assert(scanf("%u",a[i]+j)==1);
}
bool Operation::empty()const{
	F(i,0,2)F(j,0,2)if(a[i][j]!=int(i!=j))return 0;
	return 1;
}

static int read(int L,int R){
	int x;
	assert(scanf("%d",&x)==1);
	assert(L<=x&&x<=R);
	return x;
}
void Data::print()const{
	printf("%u %u\n",x[0],x[1]);
}

int main(){
	const int N=1e5+7,M=1e5+7;
	static int x[M],y[M],fa[N];
	static Operation o[M][2];
	static Data d0[N],ans[M][2];
	int n=read(1,1e5);
	int m=read(1,1e5);
	F(i,2,n+1)fa[i]=read(1,i-1);
	F(i,1,n+1)d0[i].read();
	F(i,0,m){
		x[i]=read(1,n);
		y[i]=read(0,n-1);
		F(j,0,2)o[i][j].read();
	}
	solve(n,m,fa,d0,x,y,o,ans);
	F(i,0,m){
		F(j,0,2){
			ans[i][j].print();
		}
		puts("");
	}
	fprintf(stderr,"cost = %lld\n",tot);
	if(tot>150000000)fprintf(stderr,"error: cost > 150000000\n");
	return 0;
}

