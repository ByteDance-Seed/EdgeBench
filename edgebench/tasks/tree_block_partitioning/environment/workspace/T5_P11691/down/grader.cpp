#include"data.h"
#include<cstdio>
#include<cassert>
static char ib[30000000],*ip=ib;
static int read(int L,int R){
	int x=0,f=1;
	while(*ip<48){
		if(*ip=='-')f=-1;
		++ip;
	}
	while(*ip>47)x=x*10+*ip++-48;
	x*=f;
	assert(L<=x&&x<=R);
	return x;
}
static unsigned int t1=0;
static struct IO{
	IO(){
		fread(ib,1,sizeof(ib),stdin)[ib]=0;
	}
	~IO(){
		//printf("%u\n",o_hash);
		fprintf(stderr,">>> %u\n",t1);
	}
}_io;
void Data::add(const Data &a,const Data &b){
	t1+=1;
	x1=a.x1+b.x1;
	x2=a.x2+b.x2;
	x3=a.x3^b.x3;
	x4=a.x4^b.x4;
}
void Data::sub(const Data &a,const Data &b){
	t1+=1;
	x1=a.x1-b.x1;
	x2=a.x2-b.x2;
	x3=a.x3^b.x3;
	x4=a.x4^b.x4;
}
void Data::clr(){
	x1=0;
	x2=0;
	x3=0;
	x4=0;
}
int main(){
	auto read_data=[&](Data &d){
		d.x1=read(1,10000);
		d.x2=d.x1*333;
		d.x3=d.x1;
		d.x4=d.x2;
	};
	auto write_data=[&](const Data &d){
		printf("%d %d %d %d\n",d.x1,d.x2,d.x3,d.x4);
	};
	const int N=5e5+7;
	int n=read(1,5e5);
	static int xy[N][2];
	static Data d[N];
	for(int i=1;i<=n;++i){
		xy[i][0]=read(-1e5,1e5);
		xy[i][1]=read(-1e5,1e5);
		read_data(d[i]);
	}
	int m=read(1,5e5);
	static int abc[N][3];
	for(int i=1;i<=m;++i){
		abc[i][0]=read(-1e4,1e4);
		abc[i][1]=read(1,1e4);
		abc[i][2]=read(-1e5,-1);
	}
	int q=read(1,5e5);
	static int lr[N][2];
	static Data ans[N];
	for(int i=1;i<=q;++i){
		lr[i][0]=read(1,m);
		lr[i][1]=read(lr[i][0],m);
		ans[i].clr();
	}
	solve(n,xy,d,m,abc,q,lr,ans);
	for(int i=1;i<=q;++i)write_data(ans[i]);
	return 0;
}