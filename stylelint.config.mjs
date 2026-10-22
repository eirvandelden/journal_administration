export default {
  extends: ["stylelint-config-standard"],
  rules: {
    // Rails generates these names: ActionView's field_error_proc and the scaffold error partial.
    "selector-class-pattern": [
      "^(?:field_with_errors|[a-z][a-z0-9]*(?:-[a-z0-9]+)*)$",
      { message: "Expected class selector to be kebab-case, or the Rails name field_with_errors" }
    ],
    "selector-id-pattern": [
      "^(?:error_explanation|[a-z][a-z0-9]*(?:-[a-z0-9]+)*)$",
      { message: "Expected id selector to be kebab-case, or the Rails name error_explanation" }
    ]
  }
};
