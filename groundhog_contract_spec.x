// Groundhog contract specification AST
//
// Discriminants match #[repr(i32)] on the Rust enums. Recursive references follow the
// xdrpp-friendly pattern used in sc_val.x (pointers for nested ContractType where needed).
//
// Excluded from goxdr in CI; intended as the canonical .x source for future Rust codegen.

namespace hogd_contract_spec {

// RFC 4506: string types must declare a max length; `<>` is unbounded (max 2^32-1 bytes).
typedef string ContractSpecString<>;

// ---------------------------------------------------------------------------
// ContractType (Rust: ContractType) — recursive union
// ---------------------------------------------------------------------------

% union ContractType;

struct ContractArrayType {
  ContractType *element;
  unsigned int len;
};

struct ContractVectorType {
  ContractType *element;
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
  Array = 16
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
  ContractType *option_inner;
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
  ContractType throws<>;
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

union ContractUnionCaseType switch (int v)
{
case 0:
  void;
case 1:
  ContractType tuple<>;
case 2:
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

union ContractTypeDef switch (int v)
{
case 0:
  ContractStructDef struct_def;
case 1:
  ContractEnumDef enum_def;
case 2:
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
  ContractType throws<>;
};

struct SpecMethodFragment {
  ContractSpecString interface_name;
  ContractSpecString interface_version;
  ContractSpecMethod method;
};

union SpecFragment switch (int v)
{
case 0:
  SpecInterfaceFragment interface_fragment;
case 1:
  SpecMethodFragment method_fragment;
case 2:
  ContractTypeDef type_def;
};

} // namespace hogd_contract_spec
