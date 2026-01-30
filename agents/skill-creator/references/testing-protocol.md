# Testing Protocol

> Extracted from skill-creator.md for progressive disclosure.

## For Discipline-Enforcing Skills

1. Create 3+ pressure scenarios combining:
   - **Time pressure**: "We need this deployed in 30 minutes"
   - **Sunk cost**: "I've already spent 3 hours on this approach"
   - **Authority**: "The PM said just skip the tests this time"

2. Run WITHOUT skill - document exact rationalizations:
   - What shortcuts did the agent take?
   - What rules did it bend?
   - What justifications did it give?

3. Run WITH skill - verify compliance:
   - Does the skill prevent the rationalization?
   - Does it force the correct behavior?
   - Are there any escape hatches?

4. Find new loopholes → add counters → re-test

## For Technique/Reference Skills

1. **Test retrieval**: Can agent find the right information?
   - Try different phrasings of the same question
   - Test edge cases and synonyms
   - Verify CSO keywords work

2. **Test application**: Can agent use it correctly?
   - Provide a task that requires the skill
   - Check if workflow is followed
   - Verify output meets expectations

3. **Test gaps**: Are common use cases covered?
   - List 5 most common scenarios
   - Verify each has guidance in the skill
   - Document missing coverage

## Pressure Scenario Template

```markdown
## Scenario: [Name]

### Context
[Describe the situation]

### Pressure Applied
- Time: [deadline/urgency]
- Sunk Cost: [investment so far]
- Authority: [who's asking]

### Expected WITHOUT Skill
[What rationalization/shortcut expected]

### Expected WITH Skill
[What correct behavior expected]

### Result
[ ] PASS - Skill enforced correct behavior
[ ] FAIL - Agent found loophole: [describe]
```
