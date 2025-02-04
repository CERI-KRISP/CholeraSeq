#!/usr/bin/env bb

(require '[babashka.cli :as cli]
         '[clojure.java.io :as io]
         '[clojure.data.csv :as csv])


(defn- csv-data->maps [csv-data-list]
  (map (fn [vkt] {:cluster (keyword (second vkt))
                  :id (first vkt)})
       csv-data-list))

;: TODO Accommodate a CSV flag
(defn- read-csv-data-edn [input-file]
  (with-open [reader (io/reader (io/file input-file))]
    (doall (->> (csv/read-csv reader #_#_:separator \tab )
                (drop 1 )
                csv-data->maps
                (group-by :cluster )))))


(defn- create-cluster-str [vector-of-maps ]
  (->> vector-of-maps
       (map (fn [mp] (str (:id mp ) "\n")) )
       (reduce str)))


(defn- write-cluster-txt [edn-data cluster-id]
  (spit
    (str "cluster." (name cluster-id) ".csv")
    (create-cluster-str (get edn-data cluster-id))))


(defn separate-clusters [{:keys [cluster-file]}]
  (let [data (read-csv-data-edn cluster-file)
        cluster-id-list (keys data)]
    (doall (map (fn [cluster-id] (write-cluster-txt data cluster-id))
                cluster-id-list))))

;; (separate-clusters "/Users/abhi/projects/ceri-choleraseq/_scratch/fastbaps_cluster/clusters.csv")

(def separate-clusters-cli-opts
  {:csv     {:desc    "Input CSV file"}})


(defn help
  [_]
  (println
   (str "A utility script to separate the clusters identified by FASTBAPS\n"
        (cli/format-opts {:spec separate-clusters-cli-opts}))))


(def cli-args
  [
   {:cmds ["csv"]
    :fn  #(separate-clusters (:opts %))
    :spec separate-clusters-cli-opts
    :args->opts [:cluster-file]}

   {:cmds [] :fn help}])


(cli/dispatch cli-args *command-line-args* {:coerce {:depth :long}})

