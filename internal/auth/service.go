//go:build !noauth

package auth

import (
	"context"
	"fmt"

	"github.com/modelcontextprotocol/registry/internal/config"
	"github.com/modelcontextprotocol/registry/internal/model"
)

// ServiceImpl implements the Service interface
type ServiceImpl struct {
	config     *config.Config
	githubAuth *GitHubDeviceAuth
}

// NewAuthService creates a new authentication service
//
//nolint:ireturn // Factory function intentionally returns interface for dependency injection
func NewAuthService(cfg *config.Config) Service {
	githubConfig := GitHubOAuthConfig{
		ClientID:     cfg.GithubClientID,
		ClientSecret: cfg.GithubClientSecret,
	}

	return &ServiceImpl{
		config:     cfg,
		githubAuth: NewGitHubDeviceAuth(githubConfig),
	}
}

func (s *ServiceImpl) StartAuthFlow(_ context.Context, _ model.AuthMethod,
	_ string) (map[string]string, string, error) {
	// return not implemented error
	return nil, "", fmt.Errorf("not implemented")
}

func (s *ServiceImpl) CheckAuthStatus(_ context.Context, _ string) (string, error) {
	// return not implemented error
	return "", fmt.Errorf("not implemented")
}

// ValidateAuth validates authentication credentials
func (s *ServiceImpl) ValidateAuth(ctx context.Context, auth model.Authentication) (bool, error) {
	// If no authentication method is specified or AuthMethodNone, allow without validation
	if auth.Method == "" || auth.Method == model.AuthMethodNone {
		// If a token is provided with AuthMethodNone, it's an error
		if auth.Token != "" && auth.Method == model.AuthMethodNone {
			return false, fmt.Errorf("token provided but authentication method is 'none'")
		}
		// Allow publication without authentication
		return true, nil
	}

	switch auth.Method {
	case model.AuthMethodGitHub:
		// Extract repo reference from the repository URL if it's not provided
		return s.githubAuth.ValidateToken(ctx, auth.Token, auth.RepoRef)
	case model.AuthMethodNone:
		// For 'none' auth method, we already handled validation above
		return true, nil
	default:
		return false, ErrUnsupportedAuthMethod
	}
}
