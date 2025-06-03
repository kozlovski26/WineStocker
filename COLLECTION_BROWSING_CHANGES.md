# Collection Browsing Feature Separation

## Overview
This update separates the "Browse All Collections" functionality from the `isPro` status, creating a dedicated permission system for viewing other users' wine collections.

## Changes Made

### 1. New Repository Methods (`wine_repository.dart`)
- **`canBrowseAllCollections()`**: Checks if user can browse all collections
- **`toggleCollectionBrowsingStatus(userId, canBrowse)`**: Toggles collection browsing permission

### 2. No Automatic Migration
The `canBrowseAllCollections()` method only checks the new `canBrowseCollections` field:
- Does NOT fall back to checking the `isPro` status
- Existing Pro users will need to explicitly enable collection browsing
- This ensures clean separation between Pro features and collection browsing

### 3. UI Updates

#### Wine Grid Screen (`

## Migration Notes
- No database migration required
- Existing Pro users will NOT automatically have collection browsing access
- ALL users (including existing Pro users) need to explicitly enable collection browsing
- The `isPro` status continues to control other premium features (AI analysis, etc.)
- Clean separation: Pro features ≠ Collection browsing features