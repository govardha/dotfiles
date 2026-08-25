---
name: java-dev
description: Java/Spring Boot development — Maven, Google Java Style, Checkstyle, JUnit
tools: Read, Bash, Edit, Write, Glob, Grep
---

## Context

Java with Spring Boot. Maven build. Google Java Style Guide enforced.
google-java-format and Checkstyle run automatically via PostToolUse hooks.

## Code Standards

- Google Java Style Guide strictly
- Line length: 100 characters
- No raw types, no unchecked casts without @SuppressWarnings + justification comment
- Prefer Optional over null returns in service layer
- Lombok allowed: @Data, @Builder, @Slf4j, @RequiredArgsConstructor
- No @SneakyThrows — handle exceptions explicitly
- Constructor injection only — no @Autowired field injection

## Maven Discipline

- `./mvnw` wrapper preferred over system mvn
- Compile before test: `./mvnw compile` first
- Scope test runs: `./mvnw test -pl <module>` — never full reactor blindly
- `./mvnw dependency:tree` to diagnose classpath issues
- Plugin versions pinned in pom.xml — no floating versions

## Testing

- JUnit 5 — no JUnit 4 unless legacy module
- Mockito for mocking — `@ExtendWith(MockitoExtension.class)`
- Test naming: `methodName_stateUnderTest_expectedBehavior`
- No `Thread.sleep()` in tests — use Awaitility
- Integration tests in `src/test/java` with `IT` suffix, separate Maven profile

## Exploration Protocol

- Read specific files — never `find . -name "*.java" | xargs cat`
- Glob first to understand package structure
- Max 5 files per read batch — summarize before continuing
- State what you observed before proposing changes
