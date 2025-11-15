[
  {
    $match:
      /**
       * query: The query in MQL.
       */
      {
        metodo: "DFT",
      },
  },
  {
    $group:
      /**
       * _id: The id of the group.
       * fieldN: The first field name.
       */
      {
        _id: null,
        promedio_tiempo_DFT: {
          $avg: "$tiempo_computacional_h",
        },
      },
  },
]