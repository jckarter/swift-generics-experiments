#include <cassert>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <chrono>
#include <memory>

struct vwtable_new {};
struct vwtable_combined {};
struct vwtable_preservemost {};
struct vwtable_classic {};
struct vwtable_neoclassic {};
struct Comparable_new {};
struct Comparable_classic {};

typedef struct gv_tag {} *gv;
typedef struct ugv_tag {} *ugv;

extern "C" {
  extern vwtable_new Int_vwtable_new;
  extern vwtable_combined Int_vwtable_combined;
  extern vwtable_preservemost Int_vwtable_preservemost;
  extern vwtable_classic Int_vwtable_classic;
  auto &Int_vwtable_neoclassic = (vwtable_neoclassic&)Int_vwtable_classic;
  extern Comparable_new Int_Comparable;
  extern Comparable_classic Int_Comparable_classic;
  extern vwtable_new Rect_vwtable_new;
  extern vwtable_combined Rect_vwtable_combined;
  extern vwtable_preservemost Rect_vwtable_preservemost;
  extern vwtable_classic Rect_vwtable_classic;
  extern vwtable_neoclassic Rect_vwtable_neoclassic;
  extern Comparable_new Rect_Comparable;
  auto &Rect_Comparable_classic = (Comparable_classic&)Rect_Comparable;
  
  extern gv generic_min_new(gv a, gv b, vwtable_new *T, Comparable_new *T_comparable, ugv out);
  extern gv generic_min_new_callop(gv a, gv b, vwtable_new *T, Comparable_new *T_comparable, ugv out);
  extern gv generic_min_combined(gv a, gv b, vwtable_combined *T, Comparable_new *T_comparable, ugv out);
  extern gv generic_min_preservemost(gv a, gv b, vwtable_preservemost *T, Comparable_new *T_comparable, ugv out);
  extern void generic_min_classic(void *a, void *b, vwtable_classic *T, Comparable_classic *T_comparable, void *out);
  extern void generic_min_neoclassic(void *a, void *b, vwtable_neoclassic *T, Comparable_classic *T_comparable, void *out);
  
  extern void generic_qsort_new(void *begin, void *end, vwtable_new *T, Comparable_new *T_comparable);
}

using Int = intptr_t;
struct Rect { double a,b,c,d; };

static const unsigned COUNT = 20000000;

void smoke_test() {
  auto Int_min_new = (Int (*)(Int, Int, vwtable_new *, Comparable_new*))generic_min_new;
  assert(Int_min_new(17, 42, &Int_vwtable_new, &Int_Comparable) == 17);
  assert(Int_min_new(17, 0, &Int_vwtable_new, &Int_Comparable) == 0);
  
  auto Int_min_combined = (Int (*)(Int, Int, vwtable_combined *, Comparable_new*))generic_min_combined;
  assert(Int_min_combined(17, 42, &Int_vwtable_combined, &Int_Comparable) == 17);
  assert(Int_min_combined(17, 0, &Int_vwtable_combined, &Int_Comparable) == 0);
  
  auto Int_min_preservemost = (Int (*)(Int, Int, vwtable_preservemost *, Comparable_new*))generic_min_preservemost;
  assert(Int_min_preservemost(17, 42, &Int_vwtable_preservemost, &Int_Comparable) == 17);
  assert(Int_min_preservemost(17, 0, &Int_vwtable_preservemost, &Int_Comparable) == 0);
  
  auto Rect_min_new = (void (*)(Rect *, Rect *, vwtable_new *, Comparable_new *, Rect *))generic_min_new;
  Rect x{0, 1, 2, 3}, y{1, 2, 3, 4}, z;
  Rect_min_new(&x, &y, &Rect_vwtable_new, &Rect_Comparable, &z);
  assert(z.a == 0 && z.b == 1 && z.c == 2 && z.d == 3);
  
  auto Rect_min_combined = (void (*)(Rect *, Rect *, vwtable_combined *, Comparable_new *, Rect *))generic_min_combined;
  Rect_min_combined(&x, &y, &Rect_vwtable_combined, &Rect_Comparable, &z);
  assert(z.a == 0 && z.b == 1 && z.c == 2 && z.d == 3);
  
  auto Rect_min_preservemost = (void (*)(Rect *, Rect *, vwtable_preservemost *, Comparable_new *, Rect *))generic_min_preservemost;
  Rect_min_preservemost(&x, &y, &Rect_vwtable_preservemost, &Rect_Comparable, &z);
  assert(z.a == 0 && z.b == 1 && z.c == 2 && z.d == 3);
}

__attribute__((noinline))
void test_Int_generic_min_new() {
  auto Int_min = (Int (*)(Int, Int, vwtable_new *, Comparable_new*))generic_min_new;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Int_min(17, 42, &Int_vwtable_new, &Int_Comparable);
}

__attribute__((noinline))
void test_Int_generic_min_new_callop() {
  auto Int_min = (Int (*)(Int, Int, vwtable_new *, Comparable_new*))generic_min_new_callop;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Int_min(17, 42, &Int_vwtable_new, &Int_Comparable);
}

__attribute__((noinline))
void test_Int_generic_min_combined() {
  auto Int_min = (Int (*)(Int, Int, vwtable_combined *, Comparable_new*))generic_min_combined;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Int_min(17, 42, &Int_vwtable_combined, &Int_Comparable);
}

__attribute__((noinline))
void test_Int_generic_min_classic() {
  auto Int_min = (Int (*)(Int *, Int *, vwtable_classic *, Comparable_classic *, Int *))generic_min_classic;
  
  Int x = 17, y = 42, z;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Int_min(&x, &y, &Int_vwtable_classic, &Int_Comparable_classic, &z);
}

__attribute__((noinline))
void test_Int_generic_min_preservemost() {
  auto Int_min = (Int (*)(Int, Int, vwtable_preservemost *, Comparable_new*))generic_min_preservemost;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Int_min(17, 42, &Int_vwtable_preservemost, &Int_Comparable);
}

__attribute__((noinline))
void test_Rect_generic_min_new() {
  Rect x{0, 1, 2, 3}, y{1, 2, 3, 4}, z;
  auto Rect_min = (void (*)(Rect *, Rect *, vwtable_new *, Comparable_new *, Rect *))generic_min_new;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Rect_min(&x, &y, &Rect_vwtable_new, &Rect_Comparable, &z);
}

__attribute__((noinline))
void test_Rect_generic_min_new_callop() {
  Rect x{0, 1, 2, 3}, y{1, 2, 3, 4}, z;
  auto Rect_min = (void (*)(Rect *, Rect *, vwtable_new *, Comparable_new *, Rect *))generic_min_new_callop;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Rect_min(&x, &y, &Rect_vwtable_new, &Rect_Comparable, &z);
}

__attribute__((noinline))
void test_Rect_generic_min_combined() {
  Rect x{0, 1, 2, 3}, y{1, 2, 3, 4}, z;
  auto Rect_min = (void (*)(Rect *, Rect *, vwtable_combined *, Comparable_new *, Rect *))generic_min_combined;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Rect_min(&x, &y, &Rect_vwtable_combined, &Rect_Comparable, &z);
}

__attribute__((noinline))
void test_Rect_generic_min_preservemost() {
  Rect x{0, 1, 2, 3}, y{1, 2, 3, 4}, z;
  auto Rect_min = (void (*)(Rect *, Rect *, vwtable_preservemost *, Comparable_new *, Rect *))generic_min_preservemost;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Rect_min(&x, &y, &Rect_vwtable_preservemost, &Rect_Comparable, &z);
}

__attribute__((noinline))
void test_Rect_generic_min_classic() {
  Rect x{0, 1, 2, 3}, y{1, 2, 3, 4}, z;
  auto Rect_classic = (void (*)(Rect *, Rect *, vwtable_classic *, Comparable_classic *, Rect *))generic_min_classic;
  
  for (unsigned i = 0; i < COUNT; ++i)
    Rect_classic(&x, &y, &Rect_vwtable_classic, &Rect_Comparable_classic, &z);
}

extern "C" void notailcall();

__attribute__((noinline))
void test_Int_generic_qsort_new(Int *begin, Int *end) {
  auto Int_qsort = (void(*)(Int*, Int*, vwtable_new *, Comparable_new*))generic_qsort_new;
  
  Int_qsort(begin, end, &Int_vwtable_new, &Int_Comparable);
  notailcall();
}

__attribute__((noinline))
void test_Rect_generic_qsort_new(Rect *begin, Rect *end) {
  auto Rect_qsort = (void(*)(Rect*, Rect*, vwtable_new *, Comparable_new*))generic_qsort_new;
  
  Rect_qsort(begin, end, &Rect_vwtable_new, &Rect_Comparable);
  notailcall();
}

__attribute__((noinline))
void test_Int_stdlib_qsort(Int *begin, Int *end) {
  qsort(begin, end - begin, sizeof(Int), [](const void *a, const void *b)->int {
    return a < b ? -1 : a == b ? 0 : 1;
  });
  notailcall();
}

__attribute__((noinline))
void test_Rect_stdlib_qsort(Rect *begin, Rect *end) {
  qsort(begin, end - begin, sizeof(Rect),
        [](const void *aa, const void *bb) -> int {
          auto a = (const Rect*)aa;
          auto b = (const Rect*)bb;
          double x = a->a - b->a;
          if (x != 0)
            return *(Int*)&x >> 32;
          x = a->b - b->b;
          if (x != 0)
            return *(Int*)&x >> 32;
          x = a->c - b->c;
          if (x != 0)
            return *(Int*)&x >> 32;
          x = a->d - b->d;
          return *(Int*)&x >> 32;
        });
  notailcall();
}

int main() {
  smoke_test();

  test_Int_generic_min_preservemost();
  test_Rect_generic_min_preservemost();
  test_Int_generic_min_new_callop();
  test_Int_generic_min_new();
  test_Rect_generic_min_new_callop();
  test_Rect_generic_min_new();
  test_Int_generic_min_combined();
  test_Rect_generic_min_combined();
  test_Int_generic_min_classic();
  test_Rect_generic_min_classic();
  
  static const size_t array_size = 1000000;
  auto Int_array_to_sort_orig = std::unique_ptr<Int[]>(new Int[array_size]);
  auto Int_array_to_sort = std::unique_ptr<Int[]>(new Int[array_size]);
  arc4random_buf(Int_array_to_sort_orig.get(), sizeof(Int) * array_size);

  auto Rect_array_to_sort_orig = std::unique_ptr<Rect[]>(new Rect[array_size]);
  auto Rect_array_to_sort = std::unique_ptr<Rect[]>(new Rect[array_size]);
  arc4random_buf(Rect_array_to_sort_orig.get(), sizeof(Rect) * array_size);
  // Constrain elements to [0.0, 2.0)
  for (unsigned i = 0; i < array_size; ++i) {
    *(Int*)&Rect_array_to_sort_orig[i].a &= 0x3FFFFFFFFFFFFFFFULL;
    *(Int*)&Rect_array_to_sort_orig[i].b &= 0x3FFFFFFFFFFFFFFFULL;
    *(Int*)&Rect_array_to_sort_orig[i].c &= 0x3FFFFFFFFFFFFFFFULL;
    *(Int*)&Rect_array_to_sort_orig[i].d &= 0x3FFFFFFFFFFFFFFFULL;
  }
  
  

  memcpy(Int_array_to_sort.get(), Int_array_to_sort_orig.get(),
         sizeof(Int) * array_size);
  test_Int_generic_qsort_new(Int_array_to_sort.get(),
                             Int_array_to_sort.get() + array_size);
  memcpy(Int_array_to_sort.get(), Int_array_to_sort_orig.get(),
         sizeof(Int) * array_size);
  test_Int_stdlib_qsort(Int_array_to_sort.get(),
                        Int_array_to_sort.get() + array_size);
  
  memcpy(Rect_array_to_sort.get(), Rect_array_to_sort_orig.get(),
         sizeof(Rect) * array_size);
  test_Rect_generic_qsort_new(Rect_array_to_sort.get(),
                              Rect_array_to_sort.get() + array_size);
  memcpy(Rect_array_to_sort.get(), Rect_array_to_sort_orig.get(),
         sizeof(Rect) * array_size);
  test_Rect_stdlib_qsort(Rect_array_to_sort.get(),
                         Rect_array_to_sort.get() + array_size);
  
}
