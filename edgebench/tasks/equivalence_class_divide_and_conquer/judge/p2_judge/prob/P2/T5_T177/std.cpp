#include<bits/stdc++.h>
#define F(i,l,r) for(int i=l;i<r;++i)
#define Fe(i,l,r) for(int i=l;i<=r;++i)
#define Fer(i,l,r) for(int i=l;i>=r;--i)
#if 0
#define pr(...) fprintf(stderr,__VA_ARGS__)
#else
#define pr(...) void(0)
#endif

typedef long long i64;
const int maxn=5e5,maxm=5e5,sN=5e3,N=maxn+10,M=maxm+10;

namespace IO{
const int BUF_SZ=1<<16;
char ib[BUF_SZ+1],*ip=ib+BUF_SZ;
void ipre(int n){
	int c=ib+BUF_SZ-ip;
	if(c<n){
		memcpy(ib,ip,c);
		ip=ib;
		fread(ib+c,1,BUF_SZ-c,stdin)[ib+c]=0;
	}
}
template<class T>
T read(T L,T R){
	ipre(100);
	T x=0,f=1;
	while(*ip<'0'||*ip>'9')if(*ip++=='-')f=-f;
	while(*ip>='0'&&*ip<='9')x=x*10+*ip++-'0';
	x*=f;
	if(!(L<=x&&x<=R)){
		std::cerr<<x<<" not in ["<<L<<","<<R<<"]\n";
		exit(1);
	}
	return x;
}
char ob[BUF_SZ+1],*op=ob;
void opre(int n){
	int c=ob+BUF_SZ-op;
	if(c<n){
		fwrite(ob,1,BUF_SZ-c,stdout);
		op=ob;
	}
}
template<class T>
void write(T x){
	opre(100);
	char ss[100],*sp=ss;
	if(x<T(0))x=-x,*op++='-';
	do *sp++=x%10+'0';while(x/=10);
	while(sp!=ss)*op++=*--sp;
}
template<class T>
void write(T x,char c){
	write(x);
	*op++=c;
}
struct __{
	__(){}
	~__(){
		fwrite(ob,1,op-ob,stdout);
	}
}_;
};
using IO::read;
using IO::write;

std::vector<int> e[N];
int dep[N],fa[N];
int lca(int a,int b){
	if(dep[a]<dep[b])std::swap(a,b);
	while(dep[a]>dep[b])a=fa[a];
	while(a!=b)a=fa[a],b=fa[b];
	return a;
}

int q[N],ql,qr,sz[N],bid[N],bidp=0,btm[N],dfn[N][2],dfp=0,idfn[N];
int bdfp=0,bidfn[N];
std::vector<int> be[N];
struct LcaSeg{
	int x,p1,p2,p3;//[p1,p2][p2+1,p3]
};
struct Block{
	int top,btm;
	std::vector<int> ps;
	std::vector<LcaSeg> ls;
}bs[N];
int B;
void dfs(int w,int f){
	bidfn[++bdfp]=w;
	bs[bidp].ps.push_back(w);
	bid[w]=bidp;
	int p1=bdfp;
	if(sz[w]>1)for(int u:e[w])if(u!=f){
		int p2=bdfp;
		dfs(u,w);
		bs[bidp].ls.push_back({w,p1,p2,bdfp});
	}
}
void new_block(int _top,int _btm){
	if(ql==qr)return;
	Block &b=bs[++bidp];
	b.top=_top;
	b.btm=_btm;
	be[_top].push_back(bidp);
	int p1=bdfp+1;
	while(ql!=qr){
		int p2=bdfp;
		int w=q[++ql];
		dfs(w,_top);
		bs[bidp].ls.push_back({_top,p1,p2,bdfp});
	}
	ql=qr=0;
}
void build_blocks(int w,int f=0){
	dep[w]=dep[f]+1;
	fa[w]=f;
	idfn[dfn[w][0]=++dfp]=w;
	
	int s=0,d=0;
	for(int x:e[w])if(x!=f){
		build_blocks(x,w);
		s+=sz[x];
		if(btm[x]){
			btm[w]=btm[x];
			++d;
		}
	}
	if(s>=B||d>=2||w==1){
		btm[w]=w;
		s=d=0;
		std::sort(e[w].begin(),e[w].end(),[](int a,int b){return sz[a]<sz[b];});
		for(int x:e[w])if(x!=f){
			if(s>=B||(btm[x]&&d)){
				new_block(w,d);
				s=d=0;
			}
			if(!d)d=btm[x];
			q[++qr]=x;
			s+=sz[x];
		}
		new_block(w,d);
		sz[w]=1;
	}else sz[w]=1+s;
	
	dfn[w][1]=dfp;
}

bool in(int x,int l,int r){return l<=x&&x<=r;}
int B1;
struct Q{
	int l,r,id,key;
	i64 ans;
	bool operator<(const Q &w)const{return key<w.key;}
}qs[N];
using std::max;
using std::min;
int cnt[N];
i64 s1[sN][sN];
int s2[N],s3[N];
const int C=32;
int main(){
	int n=read(1,maxn);
	int m=read(1,maxm);
	B1=sqrt(n);
	B=sqrt(n*1.7);
	Fe(i,2,n){
		int x=read(1,n),y=read(1,n);
		e[x].push_back(y);
		e[y].push_back(x);
	}
	
	build_blocks(1);
	Block &rt=bs[++bidp];
	rt.top=rt.btm=1;
	rt.ps.push_back(1);
	
	Fe(i,1,m){
		int l=read(1,n),r=read(l,n);
		qs[i]={l,r,i,l/B1*B1+r%B1,0};
	}
	std::sort(qs+1,qs+m+1);
	fprintf(stderr,"bc=%d n=%d\n",bidp,n);
	Fe(bi,1,bidp){
		Block &b=bs[bi];
		auto *ps=b.ps.data();
		int pp=(int)b.ps.size();
		std::sort(ps,ps+pp);
		
		Fe(i,0,n)cnt[i]=0;
		cnt[b.top]=1;
		F(i,0,pp)cnt[ps[i]]=1;
		Fe(i,1,n)cnt[i]+=cnt[i-1];
		int cn=cnt[n];
		
		Fe(L,1,cn+1)Fe(R,L-1,cn)s1[L][R]=0;
		
		for(auto &z:b.ls){
			int z0=cnt[z.x];
			Fe(i,z.p1,z.p2){
				int x=bidfn[i];
				int L=z0,R=cnt[x];
				if(L>R)std::swap(L,R);
				Fe(j,z.p2+1,z.p3){
					int y=bidfn[j];
					int y0=cnt[y];
					++s1[min(L,y0)][max(R,y0)];
				}
			}
		}
		
		if(b.btm){
			F(i,0,pp){
				int x=ps[i];
				int z=lca(x,b.btm);
				int x0=cnt[x],z0=cnt[z];
				if(x0>z0)std::swap(x0,z0);
				s1[x0][z0]+=(1LL<<C);
			}
			int L=dfn[b.btm][0]+1,R=dfn[b.btm][1];
			Fe(i,0,n)s2[i]=0;
			Fe(i,L,R)++s2[idfn[i]];
			Fe(i,1,n)s2[i]+=s2[i-1];
		}
		
		Fer(L,cn,1){
			Fe(R,L,cn)s1[L][R]+=s1[L][R-1];
			Fe(R,L,cn)s1[L][R]+=s1[L+1][R];
		}
		
		Fe(qi,1,m){
			Q &q=qs[qi];
			int l=cnt[q.l-1]+1,r=cnt[q.r];
			i64 v=s1[l][r];
			int v1=v&((1LL<<C)-1),v2=(v>>C);
			q.ans+=v1;
			if(v2){
				q.ans+=i64(v2)*(s2[q.r]-s2[q.l-1]);
			}
		}
	}
	Fe(bi,1,bidp){
		Block &b=bs[bi];
		if(!b.btm||be[b.btm].size()<=1)continue;
		Fe(i,1,m)s3[i]=0;
		for(int w:be[b.btm]){
			Block &b1=bs[w];
			
			Fe(i,0,n)s2[i]=0;
			for(int x:b1.ps)++s2[x];
			int L=dfn[b1.btm][0]+1,R=dfn[b1.btm][1];
			if(R-L<n/2){
				Fe(i,L,R)++s2[idfn[i]];
				Fe(i,1,n)s2[i]+=s2[i-1];
			}else
			Fe(i,1,n){
				if(L<=dfn[i][0]&&dfn[i][0]<=R)s2[i]+=1;
				s2[i]+=s2[i-1];
			}
			
			Fe(qi,1,m){
				Q &q=qs[qi];
				if(in(b.btm,q.l,q.r)){
					int v1=s2[q.r]-s2[q.l-1];
					int v2=s3[qi];
					s3[qi]+=v1;
					q.ans+=i64(v1)*v2;
				}
			}
		}
	}
	static i64 ans[N];
	Fe(i,1,m)ans[qs[i].id]=qs[i].ans;
	Fe(i,1,m)write(ans[i],'\n');
	return 0;
}
