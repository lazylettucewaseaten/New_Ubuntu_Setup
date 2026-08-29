#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

struct LazySegTree {
    int n;
    vector<long long> tree;
    vector<long long> lazy;

    LazySegTree(int n) {
        this->n = n;
        tree.assign(4 * n + 1, 0);
        lazy.assign(4 * n + 1, 0);
    }

    // Push the pending updates to children
    void push(int node) {
        if (lazy[node] != 0) {
            lazy[2 * node] += lazy[node];
            tree[2 * node] += lazy[node];
            
            lazy[2 * node + 1] += lazy[node];
            tree[2 * node + 1] += lazy[node];
            
            lazy[node] = 0;
        }
    }

    // Build the initial tree from the prefix sum array
    void build(int node, int start, int end, const vector<int>& arr) {
        if (start == end) {
            tree[node] = arr[start];
            return;
        }
        int mid = (start + end) / 2;
        build(2 * node, start, mid, arr);
        build(2 * node + 1, mid + 1, end, arr);
        tree[node] = min(tree[2 * node], tree[2 * node + 1]);
    }

    // Add 'val' to range [l, r]
    void update(int node, int start, int end, int l, int r, long long val) {
        if (r < start || end < l) return; // Out of bounds
        
        if (l <= start && end <= r) {     // Completely inside
            tree[node] += val;
            lazy[node] += val;
            return;
        }
        
        push(node);
        int mid = (start + end) / 2;
        update(2 * node, start, mid, l, r, val);
        update(2 * node + 1, mid + 1, end, l, r, val);
        tree[node] = min(tree[2 * node], tree[2 * node + 1]);
    }

    // Get the minimum in range [l, r]
    long long query(int node, int start, int end, int l, int r) {
        if (r < start || end < l) return 1e18; // Return infinity for out of bounds
        
        if (l <= start && end <= r) return tree[node]; // Completely inside
        
        push(node);
        int mid = (start + end) / 2;
        long long p1 = query(2 * node, start, mid, l, r);
        long long p2 = query(2 * node + 1, mid + 1, end, l, r);
        return min(p1, p2);
    }
};
