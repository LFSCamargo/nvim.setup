export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Types and a subject are required; a scope is not.
    'scope-empty': [0],
  },
};
