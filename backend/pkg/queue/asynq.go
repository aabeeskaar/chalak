package queue

import (
	"context"
	"fmt"

	"github.com/hibiken/asynq"
)

type Client struct {
	client *asynq.Client
}

type Server struct {
	server *asynq.Server
	mux    *asynq.ServeMux
}

func NewClient(redisAddr, password string, db int) *Client {
	client := asynq.NewClient(asynq.RedisClientOpt{
		Addr:     redisAddr,
		Password: password,
		DB:       db,
	})

	return &Client{client: client}
}

func NewServer(redisAddr, password string, db int, concurrency int) *Server {
	srv := asynq.NewServer(
		asynq.RedisClientOpt{
			Addr:     redisAddr,
			Password: password,
			DB:       db,
		},
		asynq.Config{
			Concurrency: concurrency,
			Queues: map[string]int{
				"critical": 6,
				"default":  3,
				"low":      1,
			},
		},
	)

	mux := asynq.NewServeMux()

	return &Server{
		server: srv,
		mux:    mux,
	}
}

func (c *Client) Enqueue(ctx context.Context, task *asynq.Task, opts ...asynq.Option) error {
	info, err := c.client.EnqueueContext(ctx, task, opts...)
	if err != nil {
		return fmt.Errorf("failed to enqueue task: %w", err)
	}
	_ = info
	return nil
}

func (c *Client) Close() error {
	return c.client.Close()
}

func (s *Server) RegisterHandler(pattern string, handler func(context.Context, *asynq.Task) error) {
	s.mux.HandleFunc(pattern, handler)
}

func (s *Server) Start() error {
	if err := s.server.Start(s.mux); err != nil {
		return fmt.Errorf("failed to start queue server: %w", err)
	}
	return nil
}

func (s *Server) Stop() {
	s.server.Shutdown()
}