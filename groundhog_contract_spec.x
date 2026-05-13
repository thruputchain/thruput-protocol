// Groundhog contract specification AST
//
// Excluded from goxdr in CI; intended as the canonical .x source for future Rust codegen.

namespace hogd {

// RFC 4506: string types must declare a max length; `<>` is unbounded (max 2^32-1 bytes).
typedef string ContractSpecString<>;

// ---------------------------------------------------------------------------
// ContractType (Rust: ContractType) — recursive union
// ---------------------------------------------------------------------------

% union ContractType;

struct ContractArrayType {
  ContractType element; // #[rust(box_ptr)]
  unsigned int len;
};

struct ContractVectorType {
  ContractType element; // #[rust(box_ptr)]
  unsigned int max_len;
};

/// Mirrors #[repr(i32)] enum ContractType in sdk_rs/groundhog-contract-spec/src/model.rs
enum ContractTypeKind {
  Void = 0,
  Bool = 1,
  U32 = 2,
  I32 = 3,
  U64 = 4,
  I64 = 5,
  U128 = 6,
  I128 = 7,
  String = 8,
  Bytes = 9,
  Address = 10,
  Option = 11,
  Vector = 12,
  Tuple = 13,
  Named = 14,
  U8 = 15,
  Array = 16,
  SignedToken = 17
};

union ContractType switch (ContractTypeKind v)
{
case Void:
  void;
case Bool:
  void;
case U32:
  void;
case I32:
  void;
case U64:
  void;
case I64:
  void;
case U128:
  void;
case I128:
  void;
case String:
  void;
case Bytes:
  void;
case Address:
  void;
case Option:
  ContractType option_inner; // #[rust(box_ptr)], #[cpp(box)]
case Vector:
  ContractVectorType vector;
case Tuple:
  ContractType tuple<>;
case Named:
  ContractSpecString named;
case U8:
  void;
case Array:
  ContractArrayType array;
case SignedToken:
  ContractSignedTokenPreimage signed_token_preimage;
};

// ---------------------------------------------------------------------------
// SignedTokenPreimage (Rust: SignedTokenPreimage)
// ---------------------------------------------------------------------------

struct ContractSignedTokenPreimage {
  ContractType preimage_type; // #[rust(box_ptr)], #[cpp(box)]
};

// ---------------------------------------------------------------------------
// Exception type wrapper (carries selector metadata alongside the type)
// ---------------------------------------------------------------------------

struct ContractExceptionType {
  unsigned hyper selector;
  ContractType ty;
};

// ---------------------------------------------------------------------------
// Fields, methods, interfaces
// ---------------------------------------------------------------------------

struct ContractField {
  ContractSpecString name;
  ContractType ty;
};

struct ContractSpecMethod {
  ContractSpecString name;
  ContractField args<>;
  ContractType return_type;
};

struct ContractSpecInterface {
  ContractSpecString name;
  ContractSpecString vers;
  ContractExceptionType throws<>;
  ContractSpecMethod methods<>;
};

// ---------------------------------------------------------------------------
// User-defined types (Rust: ContractTypeDef and components)
// ---------------------------------------------------------------------------

struct ContractStructDef {
  ContractSpecString name;
  ContractField fields<>;
};

struct ContractEnumVariant {
  ContractSpecString name;
  int value;
};

struct ContractEnumDef {
  ContractSpecString name;
  ContractEnumVariant variants<>;
};

/// Mirrors #[repr(i32)] enum ContractUnionCaseType in sdk_rs/groundhog-contract-spec/src/model.rs
/// (goxdr requires enum tags unique across the namespace; names prefixed for uniqueness.)
enum ContractUnionCaseKind {
  UnionCaseVoid = 0,
  UnionCaseTuple = 1,
  UnionCaseStruct = 2
};

union ContractUnionCaseType switch (ContractUnionCaseKind v)
{
case UnionCaseVoid:
  void;
case UnionCaseTuple:
  ContractType tuple<>;
case UnionCaseStruct:
  ContractField struct_fields<>;
};

struct ContractUnionCase {
  ContractSpecString name;
  int discriminant;
  ContractUnionCaseType case_type;
};

struct ContractUnionDef {
  ContractSpecString name;
  ContractUnionCase cases<>;
};

enum ContractTypeDefKind {
  TypeDefStruct = 0,
  TypeDefEnum = 1,
  TypeDefUnion = 2
};

union ContractTypeDef switch (ContractTypeDefKind v)
{
case TypeDefStruct:
  ContractStructDef struct_def;
case TypeDefEnum:
  ContractEnumDef enum_def;
case TypeDefUnion:
  ContractUnionDef union_def;
};

// ---------------------------------------------------------------------------
// Full spec (Rust: ContractSpec)
// ---------------------------------------------------------------------------

struct ContractSpec {
  ContractSpecInterface interfaces<>;
  ContractTypeDef type_defs<>;
};

// ---------------------------------------------------------------------------
// Spec fragments (Rust: SpecFragment and components)
// ---------------------------------------------------------------------------

struct SpecInterfaceFragment {
  ContractSpecString interface_name;
  ContractSpecString interface_version;
  ContractExceptionType throws<>;
};

struct SpecMethodFragment {
  ContractSpecString interface_name;
  ContractSpecString interface_version;
  ContractSpecMethod method;
};

enum SpecFragmentKind {
  SpecInterface = 0,
  SpecMethod = 1,
  SpecTypeDef = 2,
  ExportedSpecTypeDef = 3,
};

union SpecFragment switch (SpecFragmentKind v)
{
case SpecInterface:
  SpecInterfaceFragment interface_fragment;
case SpecMethod:
  SpecMethodFragment method_fragment;
case SpecTypeDef:
case ExportedSpecTypeDef:
  ContractTypeDef type_def;
};

} // namespace hogd
