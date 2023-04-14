package connectors

import (
	"context"

	pb "Hatchi/backend/proto"
)

// add new connectors here
var databases = map[string]connector{
	"sqlite": newSqliteConnector(":memory"),
}

// methods the connector must implement
type connector interface {
	Execute(context.Context, *pb.Query) (*pb.QueryResult, error)
}
