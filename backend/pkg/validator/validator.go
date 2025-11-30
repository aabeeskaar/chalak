package validator

import (
	"fmt"

	"github.com/go-playground/validator/v10"
)

type Validator struct {
	validate *validator.Validate
}

func New() *Validator {
	v := validator.New()

	return &Validator{
		validate: v,
	}
}

func (v *Validator) Validate(data interface{}) map[string]interface{} {
	err := v.validate.Struct(data)
	if err == nil {
		return nil
	}

	errors := make(map[string]interface{})

	for _, err := range err.(validator.ValidationErrors) {
		field := err.Field()
		tag := err.Tag()

		var message string
		switch tag {
		case "required":
			message = fmt.Sprintf("%s is required", field)
		case "email":
			message = fmt.Sprintf("%s must be a valid email", field)
		case "min":
			message = fmt.Sprintf("%s must be at least %s characters", field, err.Param())
		case "max":
			message = fmt.Sprintf("%s must be at most %s characters", field, err.Param())
		case "gte":
			message = fmt.Sprintf("%s must be greater than or equal to %s", field, err.Param())
		case "lte":
			message = fmt.Sprintf("%s must be less than or equal to %s", field, err.Param())
		default:
			message = fmt.Sprintf("%s is invalid", field)
		}

		errors[field] = message
	}

	return errors
}