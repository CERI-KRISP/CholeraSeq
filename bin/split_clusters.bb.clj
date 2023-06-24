#!/usr/bin/env bb

(require '[babashka.cli :as cli]
         '[clojure.java.io :as io]
         '[clojure.data.csv :as csv])


(defn- csv-data->maps [csv-data-list]
  (map (fn [vkt] {:cluster (keyword (second vkt))
                  :id (first vkt)})
       csv-data-list))


(defn- read-csv-data-edn [input-file]
  (with-open [reader (io/reader (io/file input-file))]
    (doall (->> (csv/read-csv reader )
                (drop 1 )
                csv-data->maps
                (group-by :cluster )))))


(defn- create-cluster-str [vector-of-maps ]
  (->> vector-of-maps
       (map (fn [mp] (str (:id mp ) "\n")) )
       (reduce str)))


(defn- write-cluster-txt [edn-data cluster-id]
  (spit
    (str "cluster." (name cluster-id) ".txt")
    (create-cluster-str (get edn-data cluster-id))))

(defn separate-clusters [cluster-file]
  (let [data (read-csv-data-edn cluster-file)
        cluster-id-list (keys data)]
    (doall (map (fn [cluster-id] (write-cluster-txt data cluster-id ))
         cluster-id-list))))


; (def table
;   [{:cmds ["tsv"]   :fn separate-clusters   :args->opts [:file]} ])

; (defn -main [& args]
;   (cli/dispatch table args {:coerce {:depth :long}}))

(separate-clusters (first *command-line-args*))

