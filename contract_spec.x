// Thruput contract specification AST
//
// Excluded from goxdr in CI; intended as the canonical .x source for future Rust codegen.

%#include "event.hh"

namespace hogd {

// RFC 4506: string types must declare a max length; `<>` is unbounded (max 2^32-1 bytes).
typedef string ContractSpecString<>;

// ---------------------------------------------------------------------------
// Spec ids
// ---------------------------------------------------------------------------

/// The identity of a user-defined type or event.
///
/// Every spec-named item — a `#[contract_type]`, a `#[contract_exception]`, a
/// `#[derive(Event)]` — is named by one of these, and every reference to one
/// resolves through it. A bare identifier cannot tell two of them apart: two
/// crates, two modules of one crate, or two major versions of one crate may
/// each declare a `Transfer`, and a spec naming both could not say which is
/// which.
///
/// The segments are carried apart rather than joined into
/// `CRATE@MAJOR::module::path::Name`, because the joined form cannot be split
/// back. `name = "..."` on a spec-named item substitutes its value verbatim —
/// a value carrying `::` spells its own segments and nothing rejects it — so
/// the boundary between the module path and the declared name is not
/// recoverable from the string. Consumers that need a display name or a
/// target-language identifier read `declared` directly; how an id is shortened
/// for display stays each codegen's business.
struct ContractSpecId {
  // Declaring crate, as Cargo names the package (`CARGO_PKG_NAME`, so
  // hyphenated). This is the spelling event signatures already hash and the
  // spelling RPC reports as an exception's crate.
  ContractSpecString crate_name;
  // Identity version: the leftmost non-zero component of the declaring
  // crate's semver ("0.1" before 1.0, "1" after), or of the item's own
  // `version = "..."` where it pins one. Semver-compatible releases share an
  // id; only a breaking release changes it.
  ContractSpecString major;
  // `module_path!()` at the declaration, verbatim -- so it leads with the
  // crate as a Rust ident (underscored), unlike `crate_name` above. Kept
  // whole because that is the one string the compiler hands the macro; the
  // generator splits nothing to fill this in. Compiler-generated, so a
  // consumer that wants the segments apart can split it safely, which is not
  // true of `declared`.
  ContractSpecString module_path;
  // The declared name. Substituted verbatim from `name = "..."` where an item
  // pins one, so it may itself contain `::` -- which is why it has its own
  // field rather than being the last `::` separated segment of a joined id.
  ContractSpecString declared;
};

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
  SignedToken = 17,
  // Contract values are exactly 32 bytes, most-significant byte first.
  // Event topics use the same bytes directly, without hashing.
  U256 = 18,
  // Contract values are exactly 32 bytes, most-significant byte first, in
  // two's-complement representation. Event topics use the same bytes directly.
  I256 = 19
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
  ContractSpecId named;
case U8:
  void;
case Array:
  ContractArrayType array;
case SignedToken:
  ContractSignedTokenPreimage signed_token_preimage;
case U256:
  void;
case I256:
  void;
};

// ---------------------------------------------------------------------------
// SignedTokenPreimage (Rust: SignedTokenPreimage)
// ---------------------------------------------------------------------------

struct ContractSignedTokenPreimage {
  ContractType *preimage_type; // #[rust(box_ptr)], #[cpp(box)]
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

/// Author-declared effects of the whole invocation, including nested calls.
/// These declarations are not compiler or runtime guarantees. They do not
/// select an execution path, change entrypoint IDs, or guarantee success.
/// Application effects include storage deltas, events, transfers and deployment.
enum ContractMethodEffect {
  // Arguments and constants only: no state or execution-context reads or effects.
  EffectPure = 1,
  // May read state and execution context; no application effects.
  EffectReadOnly = 2,
  // May produce application effects; need not change state on every invocation.
  EffectStateChanging = 3
};

struct ContractSpecMethod {
  ContractSpecString name;
  ContractField args<>;
  ContractType return_type;
  // Absent when unannotated; never assume read-only from absence.
  ContractMethodEffect *effect;
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
  ContractSpecId name;
  ContractField fields<>;
};

struct ContractEnumVariant {
  ContractSpecString name;
  int value;
};

struct ContractEnumDef {
  ContractSpecId name;
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
  ContractSpecId name;
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
// Event definitions (Rust: ContractEventDef)
// ---------------------------------------------------------------------------

/// Describes an event emitted via the LogEvent syscall (see event.x).
/// Topic 0 is always the event signature:
///   sha256(MAJOR_VERSION :: CRATE_NAME :: TYPE_NAME)
/// Topic fields and payload fields are listed separately, each in
/// declaration order. Topic values that are not already 32 bytes wide are
/// XDR-encoded and sha256-hashed; payload fields are XDR-encoded in order
/// to form the event data.
struct ContractEventDef {
  ContractSpecId name;
  Topic signature;          // topic 0
  ContractField topics<>;   // topics 1.. ; at most kMaxTopics-1 entries
  ContractField fields<>;   // payload, XDR-encoded in order
};

// ---------------------------------------------------------------------------
// Full spec (Rust: ContractSpec)
// ---------------------------------------------------------------------------

struct ContractSpec {
  ContractSpecInterface interfaces<>;
  ContractTypeDef type_defs<>;
  ContractEventDef events<>;
};

} // namespace hogd
