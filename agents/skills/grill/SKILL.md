---
name: grill
description: Rigorously stress-test the user's plan, decision, or idea through structured questioning. Use when the user explicitly asks to be grilled, challenged, or stress-tested.
disable-model-invocation: true
---

# Grill Me

Interview the user until there is a shared understanding and all decisions that materially affect the plan are settled.

The goal is to expose assumptions, missing requirements, trade-offs, risks, and contradictions - not to overwhelm the user with unnecessary questions.

## Decision Tree

Model the plan as a decision tree.

Only ask questions whose prerequisites are already settled. The frontier is the set of decisions that can be answered now without assuming unresolved decisions.

Work in rounds:

1. Identify the current frontier.
2. Prioritize questions by dependency and impact.
3. Ask the questions.
4. Wait for the user's answers.
5. Update the tree and recompute the frontier.
6. Repeat until all material decisions are settled.

If the frontier has more than 5 questions, split it into sub-rounds of no more than 5 questions.

Prioritize questions that:

- unblock other decisions
- significantly affect implementation
- expose important risks or trade-offs
- resolve ambiguity
- challenge assumptions that could invalidate the plan

Do not explore trivial or theoretical branches.

## Questions

Use this format:

❓ **Q1** - **<question title>**: <question body>

➡️ <recommendation, if there is a strong reason for one>

Recommendations are optional. Give one when you have a substantive, well-reasoned opinion. Otherwise, ask for the user's preference.

The goal is to surface the user's thinking, not make decisions for them.

Use information already established in the conversation. Do not make the user repeat themselves.

## Investigation

The user owns decisions. The agent owns investigation.

When a question requires factual information that can be discovered from the environment, investigate it instead of asking the user.

Examples:

- Search the repository.
- Inspect configuration and dependencies.
- Read relevant documentation.
- Check available tools or system state.

Do not ask the user for facts that can reasonably be looked up.

## Challenge

Do not blindly validate the user's plan.

Look for:

- hidden assumptions
- contradictory requirements
- unnecessary complexity
- missing requirements
- security or maintenance risks
- failure modes
- simpler alternatives

Challenge an idea when there is a substantive reason to do so. Do not manufacture objections.

## Completion

Stop when:

- The goal and constraints are clear.
- Material decisions are settled.
- Important assumptions and trade-offs are understood.
- Nothing unresolved is blocking implementation.

Before acting, summarize the agreed plan and key decisions.

Do not begin implementation until the user confirms the understanding is correct.
