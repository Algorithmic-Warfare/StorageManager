import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  namespace: "sm_v0_2_0",
  systems: {
    StorageSystem: {
      name: "StorageSystem",
      openAccess: true,
    },
    BucketSystem: {
      name: "BucketSystem",
      openAccess: true,
    },
    StoreAuthSystem: {
      name: "StoreAuthSystem",
      openAccess: true,
    },
    StoreProxySystem: {
      name: "StoreProxySystem",
      openAccess: true,
    },
    StoreLogicSystem: {
      name: "StoreLogicSystem",
      openAccess: true,
    },
    SmUtilsSystem: {
      name: "SmUtilsSystem",
      openAccess: true,
    },
    AccessUtilsSystem: {
      name: "AccessUtilSystem",
      openAccess: true,
    }
  },
  codegen: {
    generateSystemLibraries: true,
  },
  userTypes: {
    ResourceId: { filePath: "@latticexyz/store/src/ResourceId.sol", type: "bytes32" },
  },
  tables: {
    // Tasklist: {
    //   schema: {
    //     id: "uint256",
    //     creator: "address",
    //     assignee: "address",
    //     deadline: "uint256",
    //     timestamp: "uint256",
    //     status: "TaskStatus",
    //     description: "string",
    //   },
    //   key: ["id"],
    // },
    BucketedInventoryItem: {
      schema: {
        bucketId: "bytes32",
        itemId: "uint256",
        exists: "bool",
        quantity: "uint64",
        index: "uint64",
      },
      key: ["bucketId", "itemId"],
    },
    BucketMetadata: {
      schema: {
        smartObjectId: "uint256",
        bucketId: "bytes32",
        exists: "bool",
        owner: "address",
        parentBucketId: "bytes32",
        name: "string",
      },
      key: ["smartObjectId", "bucketId"],
    },
    BucketConfig: {
      schema: {
        bucketId: "bytes32",
        accessSystemId: "ResourceId",
      },
      key: ["bucketId"],
    },
    InventoryBalances: {
      schema: {
        smartObjectId: "uint256",
        itemId: "uint256",
        exists: "bool",
        quantity: "uint64",
      },
      key: ["smartObjectId", "itemId"],
    },
    // StoreSysConfig: {
    //   schema: {
    //     smartObjectId: "uint256",
    //     exists: "bool",
    //     isImmutable: "bool",
    //   },
    //   key: ["smartObjectId"],
    // },
    BucketOwners: {
      schema: {
        smartObjectId: "uint256",
        owner: "address",
        exists: "bool",
        bucketIds: "bytes32[]",
      },
      key: ["smartObjectId", "owner"],
    },
    BucketInventory: {
      schema: {
        smartObjectId: "uint256",
        bucketId: "bytes32",
        exists: "bool",
        items: "uint256[]",
      },
      key: ["smartObjectId", "bucketId"],
    },
  },

  //   enums: {
  //     TaskStatus: ["OPEN", "CLOSED"],
  //   },
});
