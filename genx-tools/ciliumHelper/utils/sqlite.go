package utils

import (
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
	"strconv"
)

var DatasourceName = "./genx-tools/ciliumHelper/CiliumClusters.sqlite3"
var database *sql.DB

func InitializeDB() *sql.DB {
	var err error
	database, err = sql.Open("sqlite3", DatasourceName)
	CheckErr(err)

	createTable()
	return database
}

func createTable() {
	sqlStmt := `CREATE TABLE IF NOT EXISTS clusters (
    				id INTEGER NOT NULL PRIMARY KEY,
					name TEXT,
					clusterId INTEGER,
					ipAddress TEXT,
					port TEXT,
					subscription TEXT,
					resourceGroup TEXT,
					isProd BOOLEAN,
					cert TEXT,
					key TEXT        
				);`
	_, err := database.Exec(sqlStmt)
	CheckErr(err)
}

func Insert(name string, clusterId string, ipAddress string, port string, subscription string, resourceGroup string, isProd string) {
	InsertWithCertificate(name, clusterId, ipAddress, port, subscription, resourceGroup, isProd, "", "")
}

func InsertWithCertificate(name string, clusterId string, ipAddress string, port string, subscription string, resourceGroup string, isProd string, cert string, key string) {
	stmt, err := database.Prepare("INSERT INTO clusters(name, clusterId, ipAddress, port, subscription, resourceGroup, isProd, cert, key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")
	CheckErr(err)

	clusterIdInt, _ := strconv.Atoi(clusterId)
	isProdBool, _ := strconv.ParseBool(isProd)
	_, err = stmt.Exec(name, clusterIdInt, ipAddress, port, subscription, resourceGroup, isProdBool, cert, key)
	CheckErr(err)
}

func ListAllClusters() []Cluster {
	var clusters []Cluster
	row, err := database.Query("SELECT id, name, clusterId, ipAddress, port, subscription, resourceGroup, isProd, key FROM clusters ORDER BY clusterId")
	CheckErr(err)

	for row.Next() {
		cluster := Cluster{}
		err := row.Scan(&cluster.ID, &cluster.Name, &cluster.ClusterID, &cluster.IP, &cluster.Port, &cluster.Subscription, &cluster.ResourceGroup, &cluster.IsProd, &cluster.Key)
		CheckErr(err)
		clusters = append(clusters, cluster)
	}
	return clusters
}

func GetByName(name string) Cluster {
	var cluster Cluster
	err := database.QueryRow("SELECT id, name, clusterId, ipAddress, port, subscription, resourceGroup, isProd, key FROM clusters WHERE name = ?", name).Scan(&cluster.ID, &cluster.Name, &cluster.ClusterID, &cluster.IP, &cluster.Port, &cluster.Subscription, &cluster.ResourceGroup, &cluster.IsProd, &cluster.Key)
	CheckErr(err)
	return cluster
}

func GetAllClustersToDo(ignoreThisName string, isProd bool) []Cluster {
	var clusters []Cluster
	row, err := database.Query("SELECT id, name, clusterId, ipAddress, port, subscription, resourceGroup, isProd, cert, key FROM clusters WHERE name != ? and isProd = ? ORDER BY clusterId DESC", ignoreThisName, isProd)
	CheckErr(err)

	for row.Next() {
		cluster := Cluster{}
		err := row.Scan(&cluster.ID, &cluster.Name, &cluster.ClusterID, &cluster.IP, &cluster.Port, &cluster.Subscription, &cluster.ResourceGroup, &cluster.IsProd, &cluster.Cert, &cluster.Key)
		CheckErr(err)
		clusters = append(clusters, cluster)
	}
	return clusters
}

func GetNextCiliumClusterId() int {
	var maxClusterId int
	err := database.QueryRow("SELECT IFNULL(MAX(clusterId) + 1, 1) FROM clusters").Scan(&maxClusterId)
	CheckErr(err)

	return maxClusterId
}

func ClusterIdExists(id int) bool {
	var exists int
	err := database.QueryRow("SELECT COUNT(1) FROM clusters WHERE clusterId = ?", id).Scan(&exists)
	CheckErr(err)

	return exists != 0
}

func ClusterNameExists(name string) bool {
	var exists int
	err := database.QueryRow("SELECT COUNT(1) FROM clusters WHERE name = ?", name).Scan(&exists)
	CheckErr(err)

	return exists != 0
}

func IpAddressExists(ipAddress string) bool {
	var exists int
	err := database.QueryRow("SELECT COUNT(1) FROM clusters WHERE ipAddress = ?", ipAddress).Scan(&exists)
	CheckErr(err)

	return exists != 0
}

type Cluster struct {
	ID            int
	Name          string
	ClusterID     int
	IP            string
	Port          string
	Subscription  string
	ResourceGroup string
	IsProd        bool
	Cert          string
	Key           string
}
