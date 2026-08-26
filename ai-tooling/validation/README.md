# Cangjie Skill validation

`language-suite` is a compiler-backed fixture for the Cangjie Developer Skill. It is not part of the machine-learning framework.

It verifies selected high-risk language patterns used by future project work: Lambda/function types, struct mutation, class/interface implementation, generics, `Option` matching, arrays, collections, and exception handling.

```powershell
cd ai-tooling/validation/language-suite
cjpm build
cjpm test --no-color
```
