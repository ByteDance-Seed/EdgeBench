//µÚÆß·Ö¿é
#include<bits/stdc++.h>
using std::min;
typedef long long i64;
const int N=1e5+7,BN=1007,Bmax=1000;
#define F(i,n) for(int i=0;i<(n);++i)
#define F3(i,l,r) for(int i=(l);i<(r);++i)
#define clr(a,n) memset((a),0,sizeof((a)[0])*(n))
char ib[1<<23],*ip=ib,ob[1<<22],*op=ob;
int read(){
	int x=0;
	while(*ip<48)++ip;
	while(*ip>47)x=x*10+*ip++-48;
	return x;
}
void print(i64 x){
	char ss[20];
	int sp=0;
	do ss[sp++]=x%10+48;while(x/=10);
	while(sp)*op++=ss[--sp];
	*op++=10;
}
void* operator new(size_t n){
	static char* l=0,*r=0;
	if(r<l+n){
		int L=1<<24;
		l=(char*)malloc(L),r=l+L,clr(l,L);
	}
	r-=n;
	return r;
}
void operator delete(void*){}
int n,m,cur_q,B;
i64 ans[N];
std::vector<int>e[N];

int id[N],idp=0,bid[N],fa[N],sz[N],btm[N],q[N],ql,qr;
struct Query{
	int d0,d1,d,id;
};
struct Block{
	int idl,sz,top,btm,*fa,*ch,*dep[2],*dsum[2][2],md[2],*dc[2];
	std::vector<Query>qs;
	void cal_dsum(int d0,int d1){
		int _md=md[d0];
		int *D0=dep[d0],*D1=dep[d1];
		int *DS=dsum[d0][d1]=new int[_md]();
		F3(i,1,sz)DS[D0[i]]+=D1[i];
		F3(i,1,_md)DS[i]+=DS[i-1];
	}
	void cal_dc(int d){
		int _md=md[d];
		int *D=dep[d];
		int *DC=dc[d]=new int[_md]();
		F3(i,1,sz)DC[D[i]]+=1;
		F3(i,1,_md)DC[i]+=DC[i-1];
	}
	void bfs(int rt,int d,int *ed,int&ds0,int&ds1,int&dc){
		clr(ed,sz);
		if(d-dep[0][rt]>md[0]){
			ds0=dsum[0][0][md[0]-1];
			if(btm)ds1=dsum[0][1][md[0]-1];
			dc=sz-1;
			for(int i=sz-1;i;--i)ed[fa[i]]+=++ed[i];
			return;
		}
		ql=qr=0;
		for(ed[q[++qr]=rt]=1;ql!=qr&&d>0;--d){
			for(int p=qr,w;ql!=p;){
				w=q[++ql];
				for(int i=ch[w];i<ch[w+1];++i)if(!ed[i])ed[q[++qr]=i]=1;
				if(!ed[fa[w]])ed[q[++qr]=fa[w]]=1;
			}
		}
		dc=qr-ed[0];
		F3(i,1,sz)ds0+=dep[0][i]*ed[i];
		if(btm)for(int i=1;i<sz;++i)ds1+=dep[1][i]*ed[i];
		for(int i=sz-1;i;--i)ed[fa[i]]+=ed[i];
	}
	i64 cal(int*a,int*b){
		i64 s=0;
		F3(i,1,sz)s+=a[i]*b[i];
		return s;
	}
	void offline(int d0,int d1);
	void init(int _top,int _btm,int bp){
		top=_top,btm=_btm;
		_top[id]=idl=idp;
		while(ql!=qr){
			int w=q[++ql];
			w[id]=++idp;
			idp[bid]=bp;
			if(w[::sz]>1)for(int u:w[e])q[++qr]=u;
		}
		sz=qr+1;
		assert(sz<=Bmax);
		fa=new int[sz]();
		ch=new int[sz+1]();
		int p=0;
		F3(i,1,sz){
			int f=fa[i]=q[i][::fa][id]-idl;
			while(p<f)ch[++p]=i;
		}
		while(p<sz)ch[++p]=sz;
		
		int *D0=dep[0]=new int[sz]();
		F3(i,1,sz)D0[i]=D0[fa[i]]+1;
		
		md[0]=D0[sz-1]+1;
		cal_dc(0);
		cal_dsum(0,0);
		
		if(btm){
			int *D1=dep[1]=new int[sz]();
			ql=qr=0;
			int rt=btm[id]-idl;
			D1[q[++qr]=rt]=1;
			while(ql!=qr){
				int w=q[++ql],d=(w==rt?0:D1[w])+1;
				for(int i=ch[w];i<ch[w+1];++i)if(!D1[i])D1[q[++qr]=i]=d;
				if(!D1[fa[w]])D1[q[++qr]=fa[w]]=d;
			}
			D1[rt]=0;
			md[1]=D1[q[qr]]+1;
			cal_dc(1);
			cal_dsum(0,1);
			cal_dsum(1,0);
			cal_dsum(1,1);
		}
	}
}bs[BN];
int bp=0;

void new_block(int _top,int _btm){
	if(ql==qr)return;
	q[0]=_top;
	++bp;
	bs[bp].init(_top,_btm,bp);
	ql=qr=0;
}
void build_blocks(int w){
	int s=0,d=0;
	for(int x:e[w]){
		build_blocks(x);
		s+=sz[x];
		if(btm[x]){
			btm[w]=btm[x];
			++d;
		}
	}
	if(s>=B||d>=2||!w){
		btm[w]=w;
		s=d=0;
		std::sort(e[w].begin(),e[w].end(),[](int a,int b){return sz[a]<sz[b];});
		for(int x:e[w]){
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
}

namespace BlockTree{
	int *fa,*ch,*cr,*d01;
	#define fore(w,i) for(int i=cr[w],i##_=cr[(w)+1];i<i##_;++i)
	void build(){
		build_blocks(0);
		assert(bp<=Bmax);
		
		fa=new int[bp+1]();
		ch=new int[bp+1]();
		cr=new int[bp+2]();
		d01=new int[bp+1]();
		for(int i=1;i<=bp;++i){
			Block&B=bs[i];
			if(B.btm)d01[i]=B.dep[0][B.btm[id]-B.idl];
			for(int j=i+1;j<=bp;++j)if(bs[j].btm==bs[i].top){
				++cr[fa[i]=j];
				break;
			}
		}
		for(int i=1;i<=bp+1;++i)cr[i]+=cr[i-1];
		for(int i=1;i<bp;++i)ch[--cr[fa[i]]]=i;
		
	}
	struct info{
		i64 ds,sz;
		void add(const info&i,int d){
			ds+=i.ds+i.sz*d;
			sz+=i.sz;
		}
		info operator-(const info&i)const{
			return {ds-i.ds,sz-i.sz};
		}
		i64 operator*(const info&i){
			return ds*i.sz+i.ds*sz;
		}
	};
	struct{
		int ed[BN],ed1[BN];
		info ds0[BN],ds1[BN];
		int b,b1,_ds0,_ds1,_dc;
		void init(int p,int d,int _b1){
			clr(ds0,bp+2);
			clr(ds1,bp+2);
			clr(ed1,bs[_b1].sz);
			
			b=p[bid],b1=_b1,_ds0=_ds1=_dc=0;
			Block&B=bs[b];
			p-=B.idl;
			B.bfs(p,d,ed,_ds0,_ds1,_dc);
			ds0[b]={_ds0,_dc};
			if(B.btm)ds1[b]={_ds1,_dc};
			
			B.qs.push_back({B.dep[0][p],(B.btm?B.dep[1][p]:0),d,cur_q});
			
			if(fa[b]){
				int f=fa[b],d1=d-B.dep[0][p];
				dfs(f,d1,1);
				fore(f,i){
					int u=ch[i];
					if(u!=b)dfs(u,d1,0);
				}
			}
			if(B.btm){
				int d1=d-B.dep[1][p];
				fore(b,i){
					int u=ch[i];
					dfs(u,d1,0);
				}
			}
		}
		
		void upd_ds(){	
			for(int w=1;w<bp;++w){
				int f=fa[w];
				ds0[f].add(ds0[w],d01[f]);
			}
			for(int w=bp;w;--w){
				fore(w,i)ds1[w].add(ds0[ch[i]],0);
				fore(w,i){
					int u=ch[i];
					ds1[u].add(ds1[w]-ds0[u],d01[u]);
				}
			}
		}
		void dfs(int w,int d,int tp){
			if(d<0)return;
			
			Block&B=bs[w];
			int d1=min(B.md[tp]-1,d),dc=B.dc[tp][d1];
			ds0[w]={B.dsum[tp][0][d1],dc};
			if(B.btm)ds1[w]={B.dsum[tp][1][d1],dc};
			
			if(w==b1){
				F3(i,1,B.sz)ed1[i]=(B.dep[tp][i]<=d);
				for(int i=B.sz-1;i;--i)ed1[B.fa[i]]+=ed1[i];
			}
			
			d-=d01[w];
			
			if(tp){
				int f=fa[w];
				if(!f)return;
				dfs(f,d,1);
				fore(f,i){
					int u=ch[i];
					if(u!=w)dfs(u,d,0);
				}
			}else fore(w,i){
				dfs(ch[i],d,0);
			}
		}
	}i0,i1;
	void query(int p0,int d0,int p1,int d1){
		i0.init(p0,d0,p1[bid]);
		i1.init(p1,d1,p0[bid]);
		i64 s=0;
		int b0=p0[bid],b1=p1[bid];
		Block&B0=bs[b0],&B1=bs[b1];
		if(b0==b1){
			s+=i0.ds0[b0]*i1.ds0[b1]-2*B0.cal(i0.ed,i1.ed);
		}else{
			s+=i0.ds0[b0]*i1.ds0[b0]-2*B0.cal(i0.ed,i1.ed1);
			s+=i0.ds0[b1]*i1.ds0[b1]-2*B1.cal(i1.ed,i0.ed1);
		}
		i0.upd_ds();
		for(int w=1;w<=bp;++w){
			fore(w,i){
				int u=ch[i];
				s+=(i0.ds1[w]-i0.ds0[u])*i1.ds0[u];
				s+=i0.ds0[u]*i1.ds1[w];
			}
		}
		ans[cur_q]+=s;
	}
	int cur_d,qs[N][2],qp[N];
	void dfs(int w,int d,int tp){
		for(Query &q:bs[w].qs){
			int _d=q.d-(tp?q.d1:q.d0)-d;
			if(_d>=0)qs[q.id][qp[q.id]++]=_d*2+cur_d;
		}
		d+=d01[w];
		if(tp){
			int f=fa[w];
			if(!f)return;
			dfs(f,d,1);
			fore(f,i){
				int u=ch[i];
				if(u!=w)dfs(u,d,0);
			}
		}else fore(w,i)dfs(ch[i],d,0);
	}
	void offline(){
		for(int w=1;w<=bp;++w){
			clr(qs,m+2);
			clr(qp,m+2);
			int f=fa[w];
			if(f){
				cur_d=0;
				dfs(f,0,1);
				fore(f,i){
					int u=ch[i];
					if(u!=w)dfs(u,0,0);
				}
			}
			cur_d=1;
			fore(w,i)dfs(ch[i],0,0);
			Block &b=bs[w];
			b.offline(0,0);
			if(b.btm){
				b.offline(0,1);
				b.offline(1,1);
			}
		}
	}
	#undef fore
}

void Block::offline(int d0,int d1){
	using BlockTree::qs;
	using BlockTree::qp;
	int mx0=md[d0],mx1=md[d1],*D0=dep[d0],*D1=dep[d1];
	static i64 tmp[BN][BN],s[BN];
	
	F(a,mx0){
		clr(s,sz);
		F3(i,1,sz)s[i]=(D0[i]<=a);
		for(int i=sz-1;i;--i)s[fa[i]]+=s[i];
		s[0]=0;
		F3(i,1,sz)s[i]+=s[fa[i]];
		
		clr(tmp[a],mx1);
		F3(i,1,sz)tmp[a][D1[i]]+=s[i];
		F3(i,1,sz)tmp[a][i]+=tmp[a][i-1];
	}
	
	for(int i=1;i<=m;++i)if(qp[i]==2){
		int a=qs[i][0],b=qs[i][1];
		if(!(((a^d0)|(b^d1))&1)){
			a=min(mx0-1,a>>1);
			b=min(mx1-1,b>>1);
			ans[i]+=dc[d0][a]*dsum[d1][0][b]+dc[d1][b]*dsum[d0][0][a]-2*tmp[a][b];
		}
	}
}

int main(){
	fread(ib,1,sizeof(ib),stdin)[ib]=0;
	n=read();
	B=sqrt(n)*1.5;
	e[0].push_back(1);
	for(int i=2;i<=n;++i){
		int f=read();
		e[f].push_back(i);
		fa[i]=f;
	}

	BlockTree::build();
	
	m=read();
	for(cur_q=1;cur_q<=m;++cur_q){
		int p0=read(),d0=read(),p1=read(),d1=read();
		BlockTree::query(p0[id],d0,p1[id],d1);
	}
	
	BlockTree::offline();
	
	for(int i=1;i<=m;++i)print(ans[i]);
	fwrite(ob,1,op-ob,stdout);
	return 0;
}
