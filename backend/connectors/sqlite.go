package connectors

import (
	pb "Hatchi/backend/proto"
	"context"
	"database/sql"
	"fmt"

	_ "github.com/mattn/go-sqlite3"
)

const port = ":9000"

type sqliteConnector struct {
	db      *sql.DB
	options *pb.ConnectionOptions
}

func newSqliteConnector() *sqliteConnector {
	// TODO: log and return the error
	string_type := "String" // can't reference a string literal, assign to var first
	options := pb.ConnectionOptions{
		Fields: []*pb.ConnectionOptionField{
			{Name: "File name", Type: &string_type, Require: true},
			{Name: "File name", Type: &string_type, Require: false}, // just for example
		},
	}

	return &sqliteConnector{options: &options}
}

func (s *sqliteConnector) Name() string {
	return "sqlite"
}

// Execute the query and read the results
func (s *sqliteConnector) Execute(ctx context.Context, query *pb.Query) (*pb.QueryResult, error) {
	rows, err := s.db.Query(query.Query)
	if err != nil {
		return nil, err
	}

	result, err := readAllRows(rows)
	if err != nil {
		return nil, err
	}

	return &pb.QueryResult{Result: result}, nil
}

func (s *sqliteConnector) ListConnectionOptions() (*pb.ConnectionOptions, error) {
	s.options.ConnectorName = s.Name()
	return s.options, nil
}

func (s *sqliteConnector) Connect(ctx context.Context, options *pb.ConnectionOptions) error {
	dbname := *(options.Fields[0].Value)
	db, err := sql.Open("sqlite3", dbname)
	if err != nil {
		return err
	}
	s.db = db
	return nil
}

func readAllRows(rows *sql.Rows) ([]*pb.Row, error) {
	// Get names of columns
	var cols []string
	cols, err := rows.Columns()
	if err != nil {
		return nil, err
	}

	// array that holds the actual data,
	// first row is always columns names
	result := []*pb.Row{{Row: cols}}

	for rows.Next() {
		row, err := readRow(rows, len(cols))
		if err != nil {
			return nil, err
		}
		result = append(result, row)
	}

	// append row to final table
	return result, nil
}

func readRow(rows *sql.Rows, rowLength int) (*pb.Row, error) {
	rawResult := make([][]byte, rowLength)              // Workaround to read *sql.RawBytes
	rawResultPointers := make([]interface{}, rowLength) // A temporary interface{} slice
	for i := range rawResult {
		rawResultPointers[i] = &rawResult[i] // Put pointers to each string in the interface slice
	}

	// start reading rows
	err := rows.Scan(rawResultPointers...)
	if err != nil {
		fmt.Println("Failed to scan row", err)
	}

	// insert row into protobuf Row Structure
	var row []string
	for _, raw := range rawResult {
		if raw == nil {
			row = append(row, "null")
		} else {
			row = append(row, string(raw))
		}
	}

	return &pb.Row{Row: row}, nil
}
