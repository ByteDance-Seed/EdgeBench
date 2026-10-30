#include"data.h"
#include<vector>
#include<algorithm>
#include<iostream>
using std::cerr;
Data (*ans)[2];
Operation (*O)[2];
int n,m,*fa,*X,*Y,cnt;
std::vector<int> v[100010];
int tot,a[20][100010],st[100010],lg[100010],d[100010],ts[100010];
int const B=320;
int sf[1600010],ss[1600010],scnt,ecnt;
struct{
	int sz,p;
	Data v;
	Operation tag;
}tr[1600010];
struct node{
	int a,b,c;
	node(int a,int b,int c):a(a),b(b),c(c){}
	node():a(),b(),c(){}
}ex[1600010];
inline void addedge(int a,int b,int c){ex[++ecnt]=node(std::min(a,b),std::max(a,b),c);}
void dfs(int x){
	a[0][tot]=fa[x],d[x]=d[fa[x]]+1,ts[st[x]=++tot]=x;
	for(auto u:v[x])dfs(u);
}
auto cmp=[](int x,int y){return d[x]<d[y];};
int lca(int x,int y){
	if(x==y) return x;
	int l=st[x],r=st[y];
	if(l>r) std::swap(l,r);
	int k=lg[r-l];
	return std::min(a[k][l],a[k][r-(1<<k)],cmp);
}
int dis(int x,int y){
	int l=lca(x,y);
	return d[x]+d[y]-2*d[l];
}
void init_tree(){
	for(int i=2;i<=n;i++) v[fa[i]].push_back(i);
	dfs(1);
	for(int i=2;i<tot;i++) lg[i]=lg[i>>1]+1;
	for(int i=1;i<=lg[tot-1];i++)
		for(int l=1;l+(1<<i)<=tot;l++)
			a[i][l]=std::min(a[i-1][l],a[i-1][l+(1<<(i-1))],cmp);
}
void build(int l,int r){
	static int h[710],trans[100010],book[100010],d[100010],y[100010],c[100010];
	int ct=0;
	for(int i=l;i<=r;i++) h[ct++]=X[i];
	std::sort(h,h+ct,[](int x,int y){return st[x]<st[y];});
	ct=std::unique(h,h+ct)-h;
	for(int i=1,j=ct;i<j;i++) h[ct++]=lca(h[i],h[i-1]);
	std::sort(h,h+ct,[](int x,int y){return st[x]<st[y];});
	ct=std::unique(h,h+ct)-h;
	for(int i=1;i<=n;i++) trans[i]=-1;
	for(int i=0;i<ct;i++) trans[h[i]]=i;
	{
		//计算每个点所在的块和块内坐标，并排序
		for(int i=1;i<=n;i++) book[i]=trans[i],d[i]=y[i]=0;
		for(int i=n;i;i--){
			int u=ts[i];
			if(book[u]!=-1&&book[fa[u]]==-1){
				book[fa[u]]=book[u];
				if(book[u]==0) y[fa[u]]=y[u]+1;
				else d[fa[u]]=d[u]+1;
			}
		}
		for(int i=1;i<=n;i++){
			int u=ts[i];
			if(book[u]==-1) book[u]=book[fa[u]],d[u]=d[fa[u]],y[u]=y[fa[u]]+1;
			c[i]=i;
		}
		//sort book 0~ct-1, d n~0, y 0~n
		static int cnt[100010],tc[100010];
		for(int i=0;i<n;i++) cnt[i]=0;
		for(int i=1;i<=n;i++) ++cnt[y[i]];
		for(int i=1;i<n;i++) cnt[i]+=cnt[i-1];
		for(int i=n;i;i--) c[cnt[y[i]]--]=i;
		for(int i=0;i<n;i++) cnt[i]=0;
		for(int i=1;i<=n;i++) ++cnt[d[c[i]]];
		for(int i=n-2;i>=0;i--) cnt[i]+=cnt[i+1];
		for(int i=n;i;i--) tc[cnt[d[c[i]]]--]=c[i];
		for(int i=0;i<ct;i++) cnt[i]=0;
		for(int i=1;i<=n;i++) ++cnt[book[tc[i]]];
		for(int i=1;i<ct;i++) cnt[i]+=cnt[i-1];
		for(int i=n;i;i--) c[cnt[book[tc[i]]]--]=tc[i];
	}
	int k=r-l+1;
	static int t[700][400],v[700][400],w[700][400];
	for(int i=0;i<ct;i++){
		for(int j=l;j<=r;j++) w[i][j-l]=Y[j]-dis(h[i],X[j]);
		w[i][k]=-1;
	}
	for(int i=0;i<=k;i++) v[0][i]=i;
	std::sort(v[0],v[0]+k+1,[&](int x,int y){return w[0][x]<w[0][y];});
	int o=1;
	for(int i=0,q=0;i<=k+1;i++)if(q){
		t[0][i]=++cnt,tr[cnt].sz=0,tr[cnt].v.clr(),tr[cnt].tag.clr();
		if(i!=0&&t[0][i-1]!=-1) addedge(t[0][i],t[0][i-1],v[0][i-1]+l);
		while(o<=n&&book[c[o]]==0&&(i==k+1||y[c[o]]<=w[0][v[0][i]])){
			++tr[cnt].sz;
			tr[cnt].v.add_eq(tr[c[o]].v),tr[cnt].p=c[o];
			sf[++scnt]=cnt,ss[scnt]=c[o];
			++o;
		}
	}else t[0][i]=-1,q=(v[0][i]==k);
	for(int x=1;x<ct;x++){
		int u=trans[lca(h[x],h[x-1])],len=::d[h[x]]-::d[h[u]];
		static int f[400],at[400],av[400],dc[400];
		// static std::vector<int> cg[100010];
		static int head[100010],end[100010],nxt[1600010],to[1600010];
		int hcnt=0;
		for(int i=0;i<=len;i++) head[i]=end[i]=0;
		const int *aw=w[u],*bw=w[x];
		for(int i=0;i<=k;i++) at[i]=t[u][i],av[i]=v[u][i],f[i]=(bw[av[i]]>aw[av[i]]),dc[i]=-1;
		int q=-1;
		for(int i=0;i<=k;i++) if(av[i]==k) q=i,f[i]=-1;
		at[k+1]=t[u][k+1];
		static int cnta[400010],*ct[2]={cnta+100003,cnta+300006};
		for(int i=0;i<=k;i++)if(i!=q)++ct[f[i]][aw[av[i]]];
		// for(int i=0;i<=len;i++) cg[i].clear(); 
		auto check=[&](int i){
			if(i==k+1||i==0) return;
			int pos;
			if(f[i-1]==1&&f[i]==0){
				pos=(aw[av[i]]-aw[av[i-1]]+1)/2;
			}else if(f[i-1]==-1&&f[i]==0){
				pos=aw[av[i]]+1;
			}else if(f[i]==-1&&f[i-1]==1){
				pos=-aw[av[i-1]]-1;
			}else return;
			if(pos<=len){
				nxt[++hcnt]=0,to[hcnt]=i;
				if(head[pos]==0) head[pos]=end[pos]=hcnt;
				else nxt[end[pos]]=hcnt,end[pos]=hcnt;
				dc[i]=pos;
			}
		};
		for(int i=1;i<=k;i++) check(i);
		for(int i=0;i<=len;i++){
			for(int j=head[i];j;j=nxt[j]){
				int k=to[j];
				if(dc[k]==i){
					dc[k]=dc[k+1]=dc[k-1]=-1;
					if(k==q) q=k-1;
					else if(k-1==q) q=k;
					std::swap(av[k],av[k-1]),std::swap(f[k],f[k-1]);
					if(k>q) at[k]=++cnt,tr[cnt].sz=0,tr[cnt].v.clr(),tr[cnt].tag.clr();else at[k]=-1;
					if(k>q) addedge(at[k],at[k+1],av[k]+l);
					if(k-1>q) addedge(at[k],at[k-1],av[k-1]+l);
					check(k-1);
					check(k+1);
				}
			}
			int e=q+ct[1][-1-i]+1;
			while(o<=n&&book[c[o]]==x&&d[c[o]]==len-i){
				if(e!=k+1&&y[c[o]]>aw[av[e]]+(f[e]?i:-i)){
					if(f[e]==0) e+=ct[0][aw[av[e]]]+ct[1][aw[av[e]]-2*i];
					else e+=ct[0][aw[av[e]]+2*i]+ct[1][aw[av[e]]];
				}
				int u=at[e];
				++tr[u].sz;
				tr[u].v.add_eq(tr[c[o]].v),tr[u].p=c[o];
				sf[++scnt]=u,ss[scnt]=c[o];
				++o;
			}
		}
		for(int i=0;i<=k;i++) ct[0][aw[av[i]]]=ct[1][aw[av[i]]]=0;
		for(int i=0;i<=k;i++) t[x][i]=at[i],v[x][i]=av[i];
		t[x][k+1]=at[k+1];
	}
}
void sort(int l,int r,int p,int q){
	static int cnt[1600010];
	static node vex[1600010];
	for(int i=p;i<=q;i++) cnt[i]=0;
	for(int i=l;i<=r;i++) ++cnt[ex[i].b];
	for(int i=p+1;i<=q;i++) cnt[i]+=cnt[i-1];
	for(int i=r;i>=l;i--) vex[--cnt[ex[i].b]]=ex[i];
	for(int i=l;i<=r;i++) ex[i]=vex[i-l];
	for(int i=p;i<=q;i++) cnt[i]=0;
	for(int i=l;i<=r;i++) ++cnt[ex[i].a];
	for(int i=p+1;i<=q;i++) cnt[i]+=cnt[i-1];
	for(int i=r;i>=l;i--) vex[--cnt[ex[i].a]]=ex[i];
	for(int i=l;i<=r;i++) ex[i]=vex[i-l];
}
void merge(int l,int r,int pl,int pr,int el,int er){
	static struct{int f,sz;}f[1600010];
	for(int i=pl;i<=pr;i++) f[i].f=i,f[i].sz=1;
	auto find=[&](int x){
		while(x!=f[x].f) x=f[x].f=f[f[x].f].f;
		return x;
	};
	auto merge=[&](int x,int y){
		x=find(x),y=find(y);
		if(x==y) return;
		if(f[x].sz>f[y].sz) f[y].f=x,f[x].sz+=f[y].sz;
		else f[x].f=y,f[y].sz+=f[x].sz;
	};
	for(int i=el;i<=er;i++){
		auto [ea,eb,ec]=ex[i];
		if(ec<l||ec>r) merge(ea,eb);
	}
	for(int i=pl;i<=pr;i++) if(f[i].f==i){
		f[i].sz=++cnt;
		tr[cnt].v=tr[i].v,tr[cnt].tag.clr(),tr[cnt].p=tr[i].p,tr[cnt].sz=tr[i].sz;
		sf[++scnt]=cnt,ss[scnt]=i;
	}
	for(int i=pl;i<=pr;i++) if(f[i].f!=i){
		int u=f[find(i)].sz;
		tr[u].v.add_eq(tr[i].v),tr[u].sz+=tr[i].sz;
		if(tr[i].sz) tr[u].p=tr[i].p;
		sf[++scnt]=u,ss[scnt]=i;
	}
	for(int i=el;i<=er;i++){
		auto [ea,eb,ec]=ex[i];
		if(l<=ec&&ec<=r) addedge(f[find(ea)].sz,f[find(eb)].sz,ec);
	}
	sort(er+1,ecnt,pr+1,cnt);
	ecnt=std::unique(ex+er+1,ex+ecnt+1,[](node const &x,node const &y){return x.a==y.a&&x.b==y.b;})-ex-1;
}
void solve(int l,int r,int pl,int pr,int el,int er){
	int tmp=scnt;
	if(el==0) build(l,r);
	else merge(l,r,pl,pr,el,er);
	if(l==r){
		ans[l][1]=ans[l][0]=Data();
		if(tr[pr+1].sz){
			if(dis(tr[pr+1].p,X[l])<=Y[l]) ans[l][0]=tr[pr+1].v,O[l][0].apply(tr[pr+1].v),O[l][0].apply(tr[pr+1].tag);
			else ans[l][1]=tr[pr+1].v,O[l][1].apply(tr[pr+1].v),O[l][1].apply(tr[pr+1].tag);
		}
		if(tr[pr+2].sz){
			if(dis(tr[pr+2].p,X[l])<=Y[l]) ans[l][0]=tr[pr+2].v,O[l][0].apply(tr[pr+2].v),O[l][0].apply(tr[pr+2].tag);
			else ans[l][1]=tr[pr+2].v,O[l][1].apply(tr[pr+2].v),O[l][1].apply(tr[pr+2].tag);
		}
	}else{
		int mid=(l+r)>>1;
		solve(l,mid,pr+1,cnt,er+1,ecnt);
		solve(mid+1,r,pr+1,cnt,er+1,ecnt);
	}
	for(int i=tmp+1;i<=scnt;i++)if(tr[ss[i]].sz){
		if(ss[i]>n) tr[sf[i]].tag.apply(tr[ss[i]].tag);
		tr[sf[i]].tag.apply(tr[ss[i]].v);
	}
	cnt=pr;
	scnt=tmp;
	ecnt=er;
}
void solve(int n,int m,int fa[],Data d0[],int x[],int y[],Operation o[][2],Data ans[][2]){
	::n=n,::m=m,::fa=fa,::X=x,::Y=y,::O=o,::ans=ans;
	init_tree();
	for(int i=1;i<=n;i++) tr[i].v=d0[i],tr[i].p=i,tr[i].sz=1;
	cnt=n;
	for(int l=0,r;l<m;l=r+1){
		r=std::min(l+B,m)-1;
		solve(l,r,1,n,0,0);
	}
}
