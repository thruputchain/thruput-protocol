#!/usr/bin/env python3
"""
Generate syscalls documentation from syscalls.yaml with validation.

This script loads the syscalls.yaml file and generates:
1. A markdown documentation file (syscalls_generated.md)
2. A JSON file with Rust doc comments (syscalls_docs.json) for inclusion in Rust code

It validates that all required fields (especially descriptions) are present.
"""

import yaml
import sys
import re
import json
from pathlib import Path
from typing import Dict, List, Any, Optional


def format_type(typename: str, yaml_data: Dict[str, Any], is_span: bool = False, 
                is_optional: bool = False, is_primitive: bool = False) -> str:
    """Format a type name for the signature using rust_name from type_mappings."""
    if is_span:
        return "[u8]"
    
    # Look up rust_name in type_mappings
    for mapping in yaml_data.get('type_mappings', []):
        if mapping.get('base_name') == typename:
            return mapping.get('rust_name', typename)
    
    # Use typename as-is if not found
    return typename


def format_signature(syscall: Dict[str, Any], yaml_data: Dict[str, Any]) -> str:
    """Format the function signature for a syscall."""
    name = syscall['name']
    
    # Format inputs
    inputs = syscall.get('inputs')
    if inputs is None:
        inputs = []
    elif not isinstance(inputs, list):
        inputs = []
    
    input_parts = []
    for inp in inputs:
        inp_name = inp['name']
        typename = inp.get('typename', '')
        is_span = inp.get('span_argument', False)
        is_optional = inp.get('optional', False)
        is_primitive = inp.get('primitive_type', False)
        
        rust_type = format_type(typename, yaml_data, is_span, is_optional, is_primitive)
        
        if is_optional:
            input_parts.append(f"{inp_name}: Option<{rust_type}>")
        else:
            input_parts.append(f"{inp_name}: {rust_type}")
    
    # Format outputs
    outputs = syscall.get('outputs')
    if outputs is None:
        outputs = []
    elif not isinstance(outputs, list):
        outputs = []
    
    output_parts = []
    for out in outputs:
        out_name = out['name']
        typename = out.get('typename', '')
        is_span = out.get('span_argument', False)
        is_optional = out.get('optional', False)
        is_primitive = out.get('primitive_type', False)
        
        rust_type = format_type(typename, yaml_data, is_span, is_optional, is_primitive)
        output_parts.append(rust_type)
    
    # Build signature with multi-line formatting for 2+ parameters
    # Format return type
    if syscall.get('returns', True) is False:
        return_str = "-> !"
    elif output_parts:
        if len(output_parts) == 1:
            return_str = f"-> {output_parts[0]}"
        else:
            return_str = "-> (" + ", ".join(output_parts) + ")"
    else:
        return_str = "-> ()"
    
    # Use single-line for 0 or 1 parameters, multi-line for 2+
    if len(input_parts) <= 1:
        # Single line format
        if input_parts:
            param_str = f"{name}(" + ", ".join(input_parts) + ")"
        else:
            param_str = f"{name}()"
        return f"{param_str} {return_str}"
    else:
        # Multi-line format
        param_lines = []
        param_lines.append(f"{name}(")
        for i, param in enumerate(input_parts):
            if i < len(input_parts) - 1:
                param_lines.append(f"  {param},")
            else:
                param_lines.append(f"  {param})")
        # Add return type to last line
        param_lines[-1] = param_lines[-1] + " " + return_str
        return "\n".join(param_lines)


def _break_at_commas(text: str) -> List[str]:
    """Break long text at commas and conjunctions, trying to keep lines under 100 chars."""
    if len(text) <= 100:
        return [text]
    
    result = []
    # Break at commas followed by space, or conjunctions (or, and, if) with spaces around them
    # Capture the delimiter to preserve it
    parts = re.split(r'(,\s+|\s+(?:or|and|if)\s+)', text)
    current_line = ""
    
    i = 0
    while i < len(parts):
        part = parts[i]
        if not part:
            i += 1
            continue
        
        # If this is a delimiter (comma or conjunction), add it to current line
        if re.match(r',\s+|\s+(?:or|and|if)\s+', part):
            test_line = current_line + part
        else:
            test_line = current_line + part if current_line else part
        
        # If adding this would exceed 100 chars and we have content, break before it
        if len(test_line.strip()) > 100 and current_line:
            result.append(current_line.strip().rstrip(','))
            current_line = part.lstrip()
        else:
            current_line = test_line
        i += 1
    
    if current_line.strip():
        result.append(current_line.strip())
    
    return result if result else [text]


def format_description(description: str) -> List[str]:
    """Format description text, breaking long lines at sentence boundaries."""
    if not description:
        return []
    
    # Split by double newlines first to preserve paragraphs
    paragraphs = description.split('\n\n')
    result_lines = []
    
    for para_idx, para in enumerate(paragraphs):
        para = para.strip()
        if not para:
            continue
        
        # Split by single newlines (which might be preserved in some cases)
        para_lines = para.split('\n')
        for line in para_lines:
            line = line.strip()
            if not line:
                if result_lines and result_lines[-1] != '':
                    result_lines.append('')
                continue
            
            # If line is very long, try to break at natural boundaries
            if len(line) > 100:
                # Try to break at sentence boundaries first (periods)
                sentence_matches = list(re.finditer(r'\.\s+(?=[A-Z])', line))
                if sentence_matches:
                    last_pos = 0
                    for match in sentence_matches:
                        sentence_end = match.end() - 1  # Position of period
                        sentence = line[last_pos:sentence_end + 1].strip()
                        if sentence:
                            # If sentence is still long, break at commas
                            if len(sentence) > 100:
                                result_lines.extend(_break_at_commas(sentence))
                            else:
                                result_lines.append(sentence)
                        last_pos = match.end()
                    # Add remaining text
                    remaining = line[last_pos:].strip()
                    if remaining:
                        if len(remaining) > 100:
                            result_lines.extend(_break_at_commas(remaining))
                        else:
                            result_lines.append(remaining)
                else:
                    # No sentence boundaries, try breaking at commas
                    if len(line) > 100:
                        result_lines.extend(_break_at_commas(line))
                    else:
                        result_lines.append(line)
            else:
                result_lines.append(line)
        
        # Add paragraph break if not last paragraph
        if para_idx < len(paragraphs) - 1 and result_lines and result_lines[-1] != '':
            result_lines.append('')
    
    return result_lines


def format_rust_doc_comment(text: str, indent: str = "") -> List[str]:
    """Format text as Rust doc comment lines (/// format)."""
    if not text:
        return []
    
    lines = format_description(text)
    result = []
    for line in lines:
        if line:
            result.append(f"{indent}/// {line}")
        else:
            result.append(f"{indent}///")
    return result


def format_errors(syscall: Dict[str, Any]) -> List[str]:
    """Format error information for a syscall. Returns list of lines."""
    errors = syscall.get('errors')
    if errors is None:
        errors = []
    elif not isinstance(errors, list):
        errors = []
    
    error_lines = ["## Errors"]
    if not errors:
        error_lines.append("- Does not return additional errors.")
        return error_lines
    
    for error in errors:
        code = error.get('code', '')
        description = error.get('description', '').strip()
        if description:
            # Format error description with line breaks
            desc_lines = format_description(description)
            if desc_lines:
                # Format as bullet with code on first line, then break after colon
                error_lines.append(f"- {code}:")
                for desc_line in desc_lines:
                    if desc_line:  # Skip empty lines in error descriptions
                        error_lines.append(f"  {desc_line}")
        else:
            error_lines.append(f"- {code}")
    
    return error_lines


def validate_syscall(syscall: Dict[str, Any], number: int) -> List[str]:
    """Validate a syscall and return list of missing fields."""
    issues = []
    name = syscall.get('name', f'<unnamed syscall {number}>')
    
    if not syscall.get('description'):
        issues.append(f"{name} (syscall {number}): Missing description")
    
    # Check that errors have descriptions if they exist
    errors = syscall.get('errors')
    if errors is None:
        errors = []
    elif not isinstance(errors, list):
        errors = []
    
    for i, error in enumerate(errors):
        code = error.get('code', '')
        if not code:
            issues.append(f"{name} (syscall {number}): Error {i+1} missing code")
        elif not error.get('description'):
            issues.append(f"{name} (syscall {number}): Error {code} missing description")
    
    return issues


def generate_markdown(yaml_data: Dict[str, Any], output_path: Path) -> List[str]:
    """Generate markdown documentation from YAML data."""
    validation_issues = []
    
    # Header text (from original syscalls.md)
    header = """All syscalls can return error kFault if a user-supplied argument points to an
invalid contract memory address.

All syscalls that return a bytespan of non-static size (a [u8], as written
here) take as one of their arguments a contract-allocated bytespan, in which
the output argument should be written, AND return a RuntimeMemoryLength
variable, which describes how much of the contract-supplied bytespan was
overwritten. We do not change any of the remaining elements of the bytespan.

"""
    
    lines = [header]
    syscalls = yaml_data.get('syscalls', [])
    
    # Sort by number to ensure correct order
    syscalls_sorted = sorted(syscalls, key=lambda s: s.get('number', -1))
    
    for syscall in syscalls_sorted:
        number = syscall.get('number', -1)
        name = syscall.get('name', f'<unnamed syscall {number}>')
        
        # Validate
        issues = validate_syscall(syscall, number)
        validation_issues.extend(issues)
        
        # Generate documentation
        lines.append(f"# {name}")
        lines.append("")
        signature = format_signature(syscall, yaml_data)
        # Handle both single-line and multi-line signatures
        lines.append("## Signature")
        sig_lines = signature.split('\n')
        for sig_line in sig_lines:
            lines.append(sig_line)
        lines.append("")
        
        description = syscall.get('description', '').strip()
        lines.append("## Description")
        if description:
            desc_lines = format_description(description)
            for line in desc_lines:
                lines.append(line)
        else:
            lines.append("(No description available)")
        
        lines.append("")
        
        error_lines = format_errors(syscall)
        # Add error lines (already formatted as list)
        for error_line in error_lines:
            lines.append(error_line)
        lines.append("")
        lines.append("")
    
    # Write output - join with newlines
    output_path.write_text('\n'.join(lines))
    
    return validation_issues


def generate_rust_docs_json(yaml_data: Dict[str, Any], output_path: Path) -> Dict[str, Dict[str, Any]]:
    """Generate JSON file with Rust documentation for each syscall."""
    syscalls = yaml_data.get('syscalls', [])
    syscalls_sorted = sorted(syscalls, key=lambda s: s.get('number', -1))
    
    docs = {}
    
    for syscall in syscalls_sorted:
        name = syscall.get('name', '')
        if not name:
            continue
        
        description = syscall.get('description', '').strip()
        errors = syscall.get('errors', [])
        if errors is None:
            errors = []
        elif not isinstance(errors, list):
            errors = []
        
        # Format description lines
        desc_lines = format_description(description) if description else []
        
        # Format error information
        error_docs = []
        for error in errors:
            code = error.get('code', '')
            error_desc = error.get('description', '').strip()
            if code:
                error_docs.append({
                    'code': code,
                    'description': format_description(error_desc) if error_desc else []
                })
        
        docs[name] = {
            'description': desc_lines,
            'errors': error_docs
        }
    
    # Write JSON file
    output_path.write_text(json.dumps(docs, indent=2))
    
    return docs


def main():
    """Main entry point."""
    script_dir = Path(__file__).parent
    yaml_path = script_dir / 'syscalls.yaml'
    markdown_output_path = script_dir / 'syscalls_generated.md'
    json_output_path = script_dir / 'syscalls_docs.json'
    
    if not yaml_path.exists():
        print(f"Error: {yaml_path} not found", file=sys.stderr)
        sys.exit(1)
    
    # Load YAML
    try:
        with open(yaml_path, 'r') as f:
            yaml_data = yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading YAML: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Generate markdown
    validation_issues = generate_markdown(yaml_data, markdown_output_path)
    
    # Generate Rust docs JSON
    generate_rust_docs_json(yaml_data, json_output_path)
    
    # Report validation issues
    if validation_issues:
        print("Validation issues found:", file=sys.stderr)
        for issue in validation_issues:
            print(f"  - {issue}", file=sys.stderr)
        print(f"\nGenerated documentation written to {markdown_output_path}", file=sys.stderr)
        print(f"Generated JSON docs written to {json_output_path}", file=sys.stderr)
        print(f"Found {len(validation_issues)} validation issue(s)", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"Successfully generated markdown documentation: {markdown_output_path}")
        print(f"Successfully generated JSON documentation: {json_output_path}")
        print("No validation issues found.")


if __name__ == '__main__':
    main()

