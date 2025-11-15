[
  {
    $match:
      /**
       * query: The query in MQL.
       */

      {
        presion_atm: {
          $gte: 1015,
        },
      },
  },
  {
    $group:
      /**
       * _id: The id of the group.
       * fieldN: The first field name.
       */
      {
        _id: "$presion_atm",
        total: {
          $sum: 1,
        },
      },
  },
]