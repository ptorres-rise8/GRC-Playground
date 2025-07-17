# Lab 03 - IAM Policy Audits Lab

## Overview

In this lab, you’re going to uncover hidden dangers in your infrastructure as code (IaC). Specifically, we’re going to focus on IAM policies—those little blocks of JSON that either lock your environment down tight or blow the doors wide open.

By the end of this walkthrough, you'll be able to:

- Detect risky permissions before they hit production  
- Understand how Rego policies work and how to write them  
- Use Conftest to scan for security violations  
- Learn why wildcard permissions and shared accounts are a bad time  
- Build your confidence as a GRC engineer with hands-on skills that matter

This lab is designed for folks who’ve never written a line of code before, but who are ready to start making sense of the alphabet soup of IAM, Rego, and policy enforcement.

No AWS credentials, no fancy tooling—just GitHub Codespaces and your brain.

---

## Controls Mapped in This Lab

Each of these NIST 800-53 controls has something to say about access management, traceability, and role enforcement. We’re covering:

- **AC-2(12)** – Ensure accounts are uniquely identifiable (no shared accounts)
- **AC-2(13)** – Enforce traceability to individual users
- **AC-3** – Enforce access control decisions
- **AC-3(4)** – Enforce separation of duties
- **AC-4** – Control information flow (no wildcards or *:* madness)
- **AC-6** – Use least privilege principles
- **AC-6(1)** – Enforce roles and job-based access
- **AC-6(9)** – Restrict access to security-relevant info/functions
- **AC-22** – Limit access to runtime policy controls and logs

---

## 1. Lab Setup (GitHub Codespaces)

Fork the [GRC Playground repo](https://github.com/ashpearce/GRC-Playground/Policy-As-Code/Lab-03-IAM-Policy-Audits) and open it in GitHub Codespaces.

Inside the repo, navigate to:

```
Policy-As-Code/Lab 03-IAM-Policy-Audits
```

---

## 2. Understand the Vulnerability

Before we write any code, let’s look at what we’re up against.

Here’s what a dangerously permissive IAM policy looks like:

- It uses `"Action": "*"` — this means **any** action is allowed. Read, write, delete, escalate privileges, turn off logging—you name it, it’s allowed.
- It uses `"Resource": "*"` — this means **everything** in the environment is fair game: all users, all buckets, all logs, all resources.
- It lacks any conditions, restrictions, or scope. There’s no limit to what this policy can access or who can assume it.

In human terms, it’s like giving someone the keys to your house, your car, your bank account—and then setting your alarm code as “1234.”

### Why is this bad?

- It violates the principle of **least privilege**  
- It makes it impossible to trace **who accessed what and why**  
- It opens the door to **privilege escalation**, **data exfiltration**, and **misuse of sensitive systems**

This kind of policy is a direct violation of multiple NIST 800-53 controls, and it’s the root cause behind multiple real-world cloud breaches.

### What are we going to do about it?

You’ll write a Rego policy that catches these mistakes and stops them before they hit production.

We’re going to build a policy-as-code safety net—one that flags these risky IAM policies early in the dev cycle, so your team can fix them before they turn into headlines.

---

## 3. Write a Vulnerable Terraform File

Open the file called `iam.tf` and paste the following:

```hcl
resource "aws_iam_policy" "bad_policy" {
  name        = "bad_policy"
  path        = "/"
  description = "A terrible idea."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}
```

Commit to the main branch.

**What’s happening here?**

- We're defining an IAM policy using Terraform syntax.
- `Action = "*"` means any action (read, write, delete, nuke your logs—anything).
- `Resource = "*"` means the action can apply to every single thing in the account.
- We’re encoding this policy as a JSON blob with `jsonencode`.

This is a textbook example of what **not** to do.

---

## 4. Simulate the Terraform Output

Terraform would normally convert this to a JSON plan file. We're skipping that complexity for now and simulating the output manually.

Open the file called `bad-policy.json` and paste this in:

```json
{
  "resource": {
    "aws_iam_policy": {
      "bad_policy": {
        "policy": {
          "Statement": [
            {
              "Effect": "Allow",
              "Action": "*",
              "Resource": "*"
            }
          ]
        }
      }
    }
  }
}
```

Commit to the main branch.

This is the structure Conftest expects when scanning a policy file. You’re pretending this is the output of your Terraform configuration.

---

## 5. Write the Rego Policy

Open the `policy` folder, then open the `iam.rego` file and paste the following:

```rego
package main

# This rule denies policies that include Action = "*"
deny[msg] {
  statement := input.resource.aws_iam_policy[_].policy.Statement[_]
  statement.Action == "*"
  msg = "Wildcard action '*' is not allowed."
}

# This rule denies policies that include Resource = "*"
deny[msg] {
  statement := input.resource.aws_iam_policy[_].policy.Statement[_]
  statement.Resource == "*"
  msg = "Wildcard resource '*' is not allowed."
}
```

Commit to the main branch.

**Let’s break this down:**

- `package main` — This names your policy. Think of it like a folder or namespace.
- `deny[msg]` — This defines a rule that, if matched, denies the configuration and returns a message.
- `statement := input.resource.aws_iam_policy[_].policy.Statement[_]` —  
  This pulls out each statement from the IAM policy block.  
  `_` is a wildcard index — basically, "give me all the things in this list."
- `statement.Action == "*"` — This checks if the statement uses an `*` action.
- `statement.Resource == "*"` — Same idea, but checking for full resource access.
- `msg = "..."` — This is the error that gets returned when the rule matches.

This Rego logic directly helps enforce **AC-3**, **AC-4**, and **AC-6**.

---

## 6. Run Conftest in Codespaces

Click the green Code button and choose Codespaces > Create codespace on main

From the root of your lab folder, run:

```bash
conftest test bad-policy.json
```

You should see:

```
FAIL - bad-policy.json - main - Wildcard action '*' is not allowed.
FAIL - bad-policy.json - main - Wildcard resource '*' is not allowed.
```

That’s your Rego policy doing its job.

---

## 7. Bonus Challenge: Fix the Policy

Try this:

- Change `Action` to something specific like `"s3:GetObject"`
- Change `Resource` to a real ARN like `"arn:aws:s3:::my-bucket/*"`

Then re-run Conftest and see if the test passes.

---

## 8. Bonus: Add GitHub Action for CI

Create the file `.github/workflows/policy-check.yml` and paste:

```yaml
name: Conftest Policy Check

on:
  push:
    paths:
      - '**/*.json'
      - '**/*.rego'
  pull_request:

jobs:
  conftest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Conftest
        run: |
          wget https://github.com/open-policy-agent/conftest/releases/download/v0.45.0/conftest_0.45.0_Linux_x86_64.tar.gz
          tar -xzf conftest_0.45.0_Linux_x86_64.tar.gz
          sudo mv conftest /usr/local/bin
      - name: Run Conftest
        run: conftest test bad-policy.json
```

Commit to the main branch.

This runs your Rego policy check every time code is pushed. It’s how you shift left like a champ.

---

## The Impact

### Case File: Capital One Data Breach

**Date:** March 2019  
**Summary:** A misconfigured IAM role allowed an attacker to exfiltrate over 100 million customer records.

**How:** The attacker accessed AWS metadata from a server, got temporary IAM credentials, and used them to run `ListBuckets` and `GetObject` on every S3 bucket.

**Root Cause:**  
- Wildcard permissions in IAM  
- No enforcement of least privilege  
- No runtime policy checks on sensitive actions

**Why this lab matters:**  
If Capital One had implemented policy-as-code checks like this one, they could’ve flagged and denied the overly permissive IAM role **before** deployment. That’s the difference between security theater and real prevention.

---

## Wrap-Up

Look at you—writing Rego like it’s your second language.

You just:

- Caught a critical IAM misconfiguration that shows up in real breaches  
- Wrote a Rego policy from scratch (go ahead, brag a little)  
- Used Conftest like a pro to enforce it  
- Learned how wildcard permissions are the cybersecurity version of handing your house keys to a raccoon

This wasn’t just a checkbox exercise. This was hands-on, real-world prep for the kind of stuff that actually matters in security. You’re no longer just reading about AC-6—you’re enforcing it. In code. Like a boss.

If you got stuck, learned something new, or had a tiny panic attack followed by a victory fist pump, I want to hear about it.

- Connect with me on [LinkedIn](https://www.linkedin.com/in/ashley-thornhill) and show off your lab  
- Found a bug or have a suggestion? Drop it as an issue in the [GRC Playground repo](https://github.com/ashpearce/GRC-Playground)  
- Want to make the next lab even better? Fork it, remix it, and tag me when it’s cooler than mine

Compliance doesn’t have to be dry, and security doesn’t have to be slow. Have fun on the playground!
