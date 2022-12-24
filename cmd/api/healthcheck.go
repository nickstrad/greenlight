package main

import (
	"net/http"
)

func (app *application) healthcheckHandler(w http.ResponseWriter, r *http.Request) {
	e := envelope{
		"status": "available",
		"system_info": map[string]string{
			"environment": app.config.env,
			"version":     version,
		},
	}

	err := app.writeJSON(w, http.StatusOK, e, nil)
	if err != nil {
		app.logger.Print(err)
		http.Error(w, STATUS_INTERNAL_SERVER_ERROR_MESSAGE, http.StatusInternalServerError)
	}
}
