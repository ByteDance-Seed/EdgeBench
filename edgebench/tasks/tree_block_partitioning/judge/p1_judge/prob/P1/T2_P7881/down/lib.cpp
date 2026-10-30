#include"lib.h"
#include<cstdio>
#include<cstdlib>
#include<cassert>

static int read(int L,int R){
	int x;
	assert(scanf("%d",&x)==1);
	assert(L<=x&&x<=R);
	return x;
}

static Data read_Data(){
	unsigned short v=read(0,1000);
	return Data{v,v,v,v};
}

static void write_Data(Data x){
	printf("(%u,%u,%u,%u)\n",(unsigned)x.a,(unsigned)x.b,(unsigned)x.c,(unsigned)x.d);
}

static bool is_id(const Data &x){
	return x.a==0&&x.b==0&&x.c==0&&x.d==0;
}

static unsigned t1=0;

void Data::operator*=(const Data &x){
	if(is_id(x))return;
	if(is_id(*this)){
		*this=x;
		return;
	}
	a+=x.a;
	b+=x.b;
	c=(c+1)*(x.c+1)-1;
	d=(d>x.d?d:x.d);
	t1+=1;
	if(t1>150000000){
		fprintf(stderr,"cost: %u\n",t1);
		exit(1);
	}
}
void Data::clr(){
	a=b=c=d=0;
}

int main(){
	const int X=1e9;
	int m=read(1,1e6);
	for(int i=0;i<m;++i){
		int tp=read(1,2);
		if(tp==1){
			int pos=read(1,X);
			int dim=read(0,1);
			Data d1=read_Data();
			Data d2=read_Data();
			update(pos,dim,d1,d2);
		}else{
			int x=read(1,X);
			int y=read(1,X);
			Data ans=query(x,y);
			write_Data(ans);
		}
	}
	fprintf(stderr,"cost: %u\n",t1);
	return 0;
}
