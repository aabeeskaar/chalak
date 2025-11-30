package logger

import (
	"context"
	"os"

	"github.com/rs/zerolog"
)

type Logger interface {
	Debug(ctx context.Context, msg string, fields map[string]interface{})
	Info(ctx context.Context, msg string, fields map[string]interface{})
	Warn(ctx context.Context, msg string, fields map[string]interface{})
	Error(ctx context.Context, msg string, err error, fields map[string]interface{})
	Fatal(ctx context.Context, msg string, err error, fields map[string]interface{})
}

type ZeroLogger struct {
	logger zerolog.Logger
}

func New(level string) *ZeroLogger {
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix

	logLevel, err := zerolog.ParseLevel(level)
	if err != nil {
		logLevel = zerolog.InfoLevel
	}

	logger := zerolog.New(os.Stdout).
		Level(logLevel).
		With().
		Timestamp().
		Caller().
		Logger()

	return &ZeroLogger{logger: logger}
}

func (l *ZeroLogger) Debug(ctx context.Context, msg string, fields map[string]interface{}) {
	event := l.logger.Debug()
	for k, v := range fields {
		event = event.Interface(k, v)
	}
	event.Msg(msg)
}

func (l *ZeroLogger) Info(ctx context.Context, msg string, fields map[string]interface{}) {
	event := l.logger.Info()
	for k, v := range fields {
		event = event.Interface(k, v)
	}
	event.Msg(msg)
}

func (l *ZeroLogger) Warn(ctx context.Context, msg string, fields map[string]interface{}) {
	event := l.logger.Warn()
	for k, v := range fields {
		event = event.Interface(k, v)
	}
	event.Msg(msg)
}

func (l *ZeroLogger) Error(ctx context.Context, msg string, err error, fields map[string]interface{}) {
	event := l.logger.Error().Err(err)
	for k, v := range fields {
		event = event.Interface(k, v)
	}
	event.Msg(msg)
}

func (l *ZeroLogger) Fatal(ctx context.Context, msg string, err error, fields map[string]interface{}) {
	event := l.logger.Fatal().Err(err)
	for k, v := range fields {
		event = event.Interface(k, v)
	}
	event.Msg(msg)
}