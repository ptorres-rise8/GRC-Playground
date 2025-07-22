# GRC Playground – IAM Policy Audits (Free Version)

Welcome to the **free version** of this lab in the GRC Playground series!  
This lab helps you understand how to detect and prevent overly permissive IAM policies using **Rego**, **Terraform**, and **Conftest**.

You’ll write and test a policy that enforces **least privilege**, flagging common misconfigurations in AWS IAM role definitions.

---

## What You’ll Learn

- How to use **policy-as-code** to detect insecure IAM policies
- How to write and test a **Rego policy** with Conftest
- How to flag `"*:*"` permissions and enforce action/resource constraints

> ⚠️ **Note:** This lab is a working free version. For the complete lab experience with guided walkthroughs, control mapping, completion badges, and bonus content, check out the [Full Lab on Gumroad](https://gumroad.com/grcplayground).

---

## Prerequisites

- Terraform ≥ 1.4.0
- Conftest ≥ 0.45.0
- GitHub Codespaces **(recommended)** or a local dev environment

---

## Quickstart

1. **Clone the repo and open in Codespaces**
2. Run:
   ```bash
   terraform init
   terraform plan -out=tfplan.binary
   terraform show -json tfplan.binary > terraform-plan.json
   conftest test --policy policy/ terraform-plan.json
The test should fail due to the bad IAM policy

## Lab Files

| File                  | Description                                           |
|-----------------------|-------------------------------------------------------|
| `iam.tf`              | Misconfigured IAM role with overly permissive access |
| `iam.rego`            | Rego policy to detect insecure statements            |
| `bad-policy.json`     | Terraform plan in JSON format for policy testing     |
| `README.md`           | Step-by-step instructions and lab overview           |

---

## Learn More
This free version gives you a hands-on look at how policy-as-code can enforce security in IAM role definitions. For the full experience, check out the paid version:

✅ Full control mapping (AC-2(12), AC-3, AC-4, etc.)
✅ Guided Notion walkthrough
✅ Completion checklist + badge
✅ Video walkthrough
✅ Bonus cheat sheets

[Get the full lab here](https://gumroad.com/grcplayground)

## Feedback
Have thoughts or ideas? Found a bug?
Open an issue or reach out to me on LinkedIn

## License
MIT: use, learn, share, and build upon it freely.
