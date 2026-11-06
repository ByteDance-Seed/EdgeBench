#include "lib.h"
#include <bits/stdc++.h>
#include <bits/extc++.h>
using namespace std;

typedef long long ll;
typedef pair <int, int> pii;

#define fi first
#define se second
#define rez resize
#define pb push_back
#define mkp make_pair
#define eb emplace_back
#define debug(...) // fprintf (stderr, __VA_ARGS__)

#define Lep(i, l, r) for (int i = l; i < r; ++ i)
#define Rep(i, r, l) for (int i = r; i > l; -- i)
#define lep(i, l, r) for (int i = l; i <= r; ++ i)
#define rep(i, r, l) for (int i = r; i >= l; -- i)

template <class T> inline void chkmin (T & x, T y) { if (x > y) x = y; }
template <class T> inline void chkmax (T & x, T y) { if (x < y) x = y; }

const int N = 1e5 + 5;
const int NS = 256;

int top;
struct Block {
	int szx, szy;
	vector <int> sx, sy;
	vector <Data> info;
} Tmp, B[(N / NS) + NS + 15];

inline void Init (const int &t) {
	B[t].szx = B[t].szy = 0, B[t].sx.clear (), B[t].sy.clear (), B[t].info.clear ();
}
inline Data GetInfo (const int &t, const int &xrk, const int &yrk) {
	return B[t].info[yrk * (B[t].szx + 1) + xrk];
}

inline void MergeBlock (const int &a, const int &b) {
	static bool typx[NS << 1], typy[NS << 1];
	debug ("MergeBlock %d, %d\n", a, b);

	/* merge sort */
	Tmp.sx.clear ();
	int txa = 0, txb = 0, ctx = 0;
	
	while (txa < B[a].szx && txb < B[b].szx)
		if (B[a].sx[txa] < B[b].sx[txb]) Tmp.sx.pb (B[a].sx[txa ++ ]), typx[ctx ++ ] = 0;
		else Tmp.sx.pb (B[b].sx[txb ++ ]), typx[ctx ++ ] = 1;

	while (txa < B[a].szx) Tmp.sx.pb (B[a].sx[txa ++ ]), typx[ctx ++ ] = 0;
	while (txb < B[b].szx) Tmp.sx.pb (B[b].sx[txb ++ ]), typx[ctx ++ ] = 1;
	Tmp.szx = Tmp.sx.size ();

	/* merge sort */
	Tmp.sy.clear ();
	int tya = 0, tyb = 0, cty = 0;
	
	while (tya < B[a].szy && tyb < B[b].szy)
		if (B[a].sy[tya] < B[b].sy[tyb]) Tmp.sy.pb (B[a].sy[tya ++ ]), typy[cty ++ ] = 0;
		else Tmp.sy.pb (B[b].sy[tyb ++ ]), typy[cty ++ ] = 1;

	while (tya < B[a].szy) Tmp.sy.pb (B[a].sy[tya ++ ]), typy[cty ++ ] = 0;
	while (tyb < B[b].szy) Tmp.sy.pb (B[b].sy[tyb ++ ]), typy[cty ++ ] = 1;
	Tmp.szy = Tmp.sy.size ();

	/* merge info */
	int tc = 0;
	Tmp.info.rez ((Tmp.sy.size () + 1) * (Tmp.sx.size () + 1));

	for (int i = 0, cya = 0, cyb = 0; i <= Tmp.szy; ++ i) {
		for (int j = 0, cxa = 0, cxb = 0; j <= Tmp.szx; ++ j) {
			Tmp.info[tc].clr ();

			Tmp.info[tc] *= GetInfo (a, cxa, cya);
			Tmp.info[tc] *= GetInfo (b, cxb, cyb);

			++ tc, (typx[j] ? ++ cxb : ++ cxa);
		}
		typy[i] ? ++ cyb : ++ cya;
	}
	B[a] = Tmp;
}

inline int Findrk (vector <int> &ver, const int pos) {
	int l = 0, r = ver.size () - 1, ans = -1, mid;
	while (l <= r) mid = l + r >> 1, ((ver[mid] <= pos) ? ans = mid, l = mid + 1 : r = mid - 1);
	return ans + 1;
}
inline void Calc (const int &t, const int &x, const int &y, Data &ans) {
	int xrk = Findrk (B[t].sx, x);
	int yrk = Findrk (B[t].sy, y);
	ans *= GetInfo (t, xrk, yrk);
}

void update (int x, int dim, Data d1, Data d2) {
	++ top, Init (top);
	if (dim == 0) B[top].sx.pb (x), B[top].szx = 1;
	else B[top].sy.pb (x), B[top].szy = 1;
	B[top].info.pb (d1), B[top].info.pb (d2);

	while (top > 1 && B[top].szx + B[top].szy < NS &&
		B[top].szx + B[top].szy == B[top - 1].szx + B[top - 1].szy)
			MergeBlock (top - 1, top), -- top;
}
Data query (int x, int y) {
	Data ans; ans.clr ();
	lep (i, 1, top) Calc (i, x, y, ans);
	return ans;
}
