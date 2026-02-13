{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  buddypress = pkgs.stdenvNoCC.mkDerivation {
    pname = "buddypress";
    version = "latest";
    src = pkgs.fetchzip {
      url = "https://downloads.wordpress.org/plugin/buddypress.latest-stable.zip";
      hash = "sha256-LSFH85BSTYfiSulZm9xcGZwm6ezLCn39LhcG/pWzVjw=";
    };
    installPhase = ''
      mkdir -p "$out"
      cp -R ./* "$out/"
    '';
  };

  elementor = pkgs.stdenvNoCC.mkDerivation {
    pname = "elementor";
    version = "latest";
    src = pkgs.fetchzip {
      url = "https://downloads.wordpress.org/plugin/elementor.latest-stable.zip";
      hash = "sha256-vosNTIteZ7KkOTK17EB1CEQdxLomP4n0qWifuCw0GL0=";
    };
    installPhase = ''
      mkdir -p "$out"
      cp -R ./* "$out/"
    '';
  };

  abilitiesApi = pkgs.stdenvNoCC.mkDerivation {
    pname = "abilities-api";
    version = "v0.4.0";
    src = pkgs.fetchzip {
      url = "https://github.com/WordPress/abilities-api/releases/download/v0.4.0/abilities-api.zip";
      hash = "sha256-a/PJZ3skTPHqBLPP2UE0eEAjBmxO7bYXlIN+Lr/3vjY=";
    };
    installPhase = ''
      mkdir -p "$out"
      cp -R ./* "$out/"
    '';
  };

  mcpAdapter = pkgs.stdenvNoCC.mkDerivation {
    pname = "mcp-adapter";
    version = "v0.4.1";
    src = pkgs.fetchzip {
      url = "https://github.com/WordPress/mcp-adapter/releases/download/v0.4.1/mcp-adapter.zip";
      hash = "sha256-bgsY3jlxtjC2laXFP1CL89HPNIl27rGAV0G99/K1elQ=";
    };
    installPhase = ''
      mkdir -p "$out"
      cp -R ./* "$out/"
    '';
  };

  landOfMemoriesMcp = pkgs.runCommandNoCC "land-of-memories-mcp" { } ''
            mkdir -p "$out"
            cat > "$out/land-of-memories-mcp.php" <<'PHP'
        <?php
        /**
         * Plugin Name: Land of Memories MCP Abilities
         * Description: MCP abilities for building and managing Land of Memories content.
         */

    $lom_register_abilities = static function () {
          $tool_meta = [
            'mcp' => [
              'public' => true,
              'type' => 'tool',
            ],
          ];

          $register_ability = static function ( $name, $label, $description, $input_schema, $execute_callback, $permission_callback ) use ( $tool_meta ) {
            wp_register_ability( $name, [
              'label' => $label,
              'description' => $description,
              'category' => 'site',
              'input_schema' => $input_schema,
              'execute_callback' => $execute_callback,
              'permission_callback' => $permission_callback,
              'meta' => $tool_meta,
            ] );
          };

          $read_permission = static function () {
            return current_user_can( 'read' );
          };

          $edit_permission = static function () {
            return current_user_can( 'edit_pages' );
          };

          $manage_permission = static function () {
            return current_user_can( 'manage_options' );
          };

          $upload_permission = static function () {
            return current_user_can( 'upload_files' );
          };

          $clear_elementor_cache = static function () {
            if ( ! class_exists( '\\Elementor\\Plugin' ) ) {
              return;
            }

            $plugin = \Elementor\Plugin::$instance;

            if ( isset( $plugin->files_manager ) && method_exists( $plugin->files_manager, 'clear_cache' ) ) {
              $plugin->files_manager->clear_cache();
            }

            if ( isset( $plugin->posts_css_manager ) && method_exists( $plugin->posts_css_manager, 'clear_cache' ) ) {
              $plugin->posts_css_manager->clear_cache();
            }
          };

          $register_ability(
            'land-of-memories/create-page',
            'Create Page',
            'Create a new WordPress page.',
            [
              'type' => 'object',
              'properties' => [
                'title' => [ 'type' => 'string' ],
                'content' => [ 'type' => 'string' ],
                'status' => [
                  'type' => 'string',
                  'enum' => [ 'draft', 'publish', 'private' ],
                  'default' => 'draft',
                ],
                'excerpt' => [ 'type' => 'string' ],
                'slug' => [ 'type' => 'string' ],
                'parent' => [ 'type' => 'integer' ],
              ],
              'required' => [ 'title' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $status = $input['status'] ?? 'draft';

              $page_id = wp_insert_post( [
                'post_type' => 'page',
                'post_title' => sanitize_text_field( (string) $input['title'] ),
                'post_content' => isset( $input['content'] ) ? (string) $input['content'] : "",
                'post_status' => in_array( $status, [ 'draft', 'publish', 'private' ], true ) ? $status : 'draft',
                'post_excerpt' => isset( $input['excerpt'] ) ? (string) $input['excerpt'] : "",
                'post_name' => isset( $input['slug'] ) ? sanitize_title( (string) $input['slug'] ) : "",
                'post_parent' => isset( $input['parent'] ) ? absint( $input['parent'] ) : 0,
              ] );

              if ( is_wp_error( $page_id ) ) {
                return [ 'success' => false, 'error' => $page_id->get_error_message() ];
              }

              return [
                'success' => true,
                'page_id' => (int) $page_id,
                'url' => get_permalink( $page_id ),
                'status' => get_post_status( $page_id ),
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/get-page',
            'Get Page',
            'Fetch full page data and relevant Elementor metadata.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
              ],
              'required' => [ 'page_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $post = get_post( $page_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Page not found.' ];
              }

              $elementor_data_raw = get_post_meta( $page_id, '_elementor_data', true );
              $elementor_data = null;

              if ( is_string( $elementor_data_raw ) && "" !== $elementor_data_raw ) {
                $decoded = json_decode( $elementor_data_raw, true );
                if ( JSON_ERROR_NONE === json_last_error() ) {
                  $elementor_data = $decoded;
                }
              }

              return [
                'success' => true,
                'page' => [
                  'id' => $page_id,
                  'title' => get_the_title( $page_id ),
                  'slug' => $post->post_name,
                  'status' => $post->post_status,
                  'content' => $post->post_content,
                  'excerpt' => $post->post_excerpt,
                  'url' => get_permalink( $page_id ),
                  'featured_image_id' => (int) get_post_thumbnail_id( $page_id ),
                  'elementor_data_raw' => $elementor_data_raw,
                  'elementor_data' => $elementor_data,
                  'elementor_page_settings' => get_post_meta( $page_id, '_elementor_page_settings', true ),
                  'elementor_edit_mode' => get_post_meta( $page_id, '_elementor_edit_mode', true ),
                  'elementor_template_type' => get_post_meta( $page_id, '_elementor_template_type', true ),
                ],
              ];
            },
            $read_permission
          );

          $register_ability(
            'land-of-memories/list-pages',
            'List Pages',
            'List pages with optional search and status filters.',
            [
              'type' => 'object',
              'properties' => [
                'search' => [ 'type' => 'string' ],
                'status' => [
                  'type' => 'string',
                  'enum' => [ 'publish', 'draft', 'private', 'any' ],
                  'default' => 'any',
                ],
                'limit' => [ 'type' => 'integer', 'default' => 20 ],
              ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $limit = isset( $input['limit'] ) ? absint( $input['limit'] ) : 20;
              $limit = max( 1, min( 100, $limit ) );

              $args = [
                'post_type' => 'page',
                'post_status' => $input['status'] ?? 'any',
                'numberposts' => $limit,
                'orderby' => 'modified',
                'order' => 'DESC',
              ];

              if ( ! empty( $input['search'] ) ) {
                $args['s'] = sanitize_text_field( (string) $input['search'] );
              }

              $posts = get_posts( $args );
              $pages = [];

              foreach ( $posts as $post ) {
                $pages[] = [
                  'id' => (int) $post->ID,
                  'title' => $post->post_title,
                  'slug' => $post->post_name,
                  'status' => $post->post_status,
                  'url' => get_permalink( $post->ID ),
                  'modified' => get_post_modified_time( DATE_ATOM, true, $post->ID ),
                ];
              }

              return [
                'success' => true,
                'count' => count( $pages ),
                'pages' => $pages,
              ];
            },
            $read_permission
          );

          $register_ability(
            'land-of-memories/update-page',
            'Update Page',
            'Update a page title, body, status, slug, and other page-level fields.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
                'title' => [ 'type' => 'string' ],
                'content' => [ 'type' => 'string' ],
                'status' => [ 'type' => 'string', 'enum' => [ 'draft', 'publish', 'private' ] ],
                'excerpt' => [ 'type' => 'string' ],
                'slug' => [ 'type' => 'string' ],
                'parent' => [ 'type' => 'integer' ],
                'menu_order' => [ 'type' => 'integer' ],
                'page_template' => [ 'type' => 'string' ],
              ],
              'required' => [ 'page_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $post = get_post( $page_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Page not found.' ];
              }

              $update_payload = [
                'ID' => $page_id,
              ];

              if ( array_key_exists( 'title', $input ) ) {
                $update_payload['post_title'] = sanitize_text_field( (string) $input['title'] );
              }

              if ( array_key_exists( 'content', $input ) ) {
                $update_payload['post_content'] = (string) $input['content'];
              }

              if ( array_key_exists( 'status', $input ) ) {
                $update_payload['post_status'] = (string) $input['status'];
              }

              if ( array_key_exists( 'excerpt', $input ) ) {
                $update_payload['post_excerpt'] = (string) $input['excerpt'];
              }

              if ( array_key_exists( 'slug', $input ) ) {
                $update_payload['post_name'] = sanitize_title( (string) $input['slug'] );
              }

              if ( array_key_exists( 'parent', $input ) ) {
                $update_payload['post_parent'] = absint( $input['parent'] );
              }

              if ( array_key_exists( 'menu_order', $input ) ) {
                $update_payload['menu_order'] = (int) $input['menu_order'];
              }

              $result = wp_update_post( $update_payload, true );

              if ( is_wp_error( $result ) ) {
                return [ 'success' => false, 'error' => $result->get_error_message() ];
              }

              if ( ! empty( $input['page_template'] ) ) {
                update_post_meta( $page_id, '_wp_page_template', sanitize_text_field( (string) $input['page_template'] ) );
              }

              return [
                'success' => true,
                'page_id' => $page_id,
                'url' => get_permalink( $page_id ),
                'status' => get_post_status( $page_id ),
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/duplicate-page',
            'Duplicate Page',
            'Duplicate a page including Elementor and custom metadata.',
            [
              'type' => 'object',
              'properties' => [
                'source_page_id' => [ 'type' => 'integer' ],
                'title' => [ 'type' => 'string' ],
                'status' => [ 'type' => 'string', 'enum' => [ 'draft', 'publish', 'private' ], 'default' => 'draft' ],
              ],
              'required' => [ 'source_page_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $source_id = absint( $input['source_page_id'] ?? 0 );
              $source = get_post( $source_id );

              if ( ! $source || 'page' !== $source->post_type ) {
                return [ 'success' => false, 'error' => 'Source page not found.' ];
              }

              $new_title = ! empty( $input['title'] )
                ? sanitize_text_field( (string) $input['title'] )
                : sprintf( '%s (Copy)', $source->post_title );

              $new_id = wp_insert_post( [
                'post_type' => 'page',
                'post_title' => $new_title,
                'post_content' => $source->post_content,
                'post_excerpt' => $source->post_excerpt,
                'post_status' => $input['status'] ?? 'draft',
                'post_parent' => (int) $source->post_parent,
                'menu_order' => (int) $source->menu_order,
              ] );

              if ( is_wp_error( $new_id ) ) {
                return [ 'success' => false, 'error' => $new_id->get_error_message() ];
              }

              $excluded_meta = [ '_edit_lock', '_edit_last', '_wp_old_slug' ];
              $meta = get_post_meta( $source_id );

              foreach ( $meta as $meta_key => $meta_values ) {
                if ( in_array( $meta_key, $excluded_meta, true ) ) {
                  continue;
                }

                foreach ( $meta_values as $meta_value ) {
                  add_post_meta( $new_id, $meta_key, maybe_unserialize( $meta_value ) );
                }
              }

              $thumbnail_id = get_post_thumbnail_id( $source_id );
              if ( $thumbnail_id ) {
                set_post_thumbnail( $new_id, $thumbnail_id );
              }

              return [
                'success' => true,
                'source_page_id' => $source_id,
                'new_page_id' => (int) $new_id,
                'url' => get_permalink( $new_id ),
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/set-front-page',
            'Set Front Page',
            'Set a page as the site front page and optionally assign posts page.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
                'posts_page_id' => [ 'type' => 'integer' ],
              ],
              'required' => [ 'page_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $post = get_post( $page_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Front page target is invalid.' ];
              }

              update_option( 'show_on_front', 'page' );
              update_option( 'page_on_front', $page_id );

              if ( array_key_exists( 'posts_page_id', $input ) ) {
                $posts_page_id = absint( $input['posts_page_id'] );
                update_option( 'page_for_posts', $posts_page_id );
              }

              return [
                'success' => true,
                'page_on_front' => (int) get_option( 'page_on_front' ),
                'page_for_posts' => (int) get_option( 'page_for_posts' ),
              ];
            },
            $manage_permission
          );

          $register_ability(
            'land-of-memories/get-elementor-data',
            'Get Elementor Data',
            'Get Elementor document data and page settings for a page.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
              ],
              'required' => [ 'page_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $post = get_post( $page_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Page not found.' ];
              }

              $data_raw = get_post_meta( $page_id, '_elementor_data', true );
              $decoded = null;

              if ( is_string( $data_raw ) && "" !== $data_raw ) {
                $parsed = json_decode( $data_raw, true );
                if ( JSON_ERROR_NONE === json_last_error() ) {
                  $decoded = $parsed;
                }
              }

              return [
                'success' => true,
                'page_id' => $page_id,
                'elementor_data_raw' => $data_raw,
                'elementor_data' => $decoded,
                'elementor_page_settings' => get_post_meta( $page_id, '_elementor_page_settings', true ),
                'elementor_edit_mode' => get_post_meta( $page_id, '_elementor_edit_mode', true ),
                'elementor_template_type' => get_post_meta( $page_id, '_elementor_template_type', true ),
              ];
            },
            $read_permission
          );

          $register_ability(
            'land-of-memories/update-elementor-data',
            'Update Elementor Data',
            'Write Elementor JSON content to a page and refresh Elementor caches.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
                'elementor_data_json' => [ 'type' => 'string' ],
                'page_settings_json' => [ 'type' => 'string' ],
                'title' => [ 'type' => 'string' ],
                'status' => [ 'type' => 'string', 'enum' => [ 'draft', 'publish', 'private' ] ],
              ],
              'required' => [ 'page_id', 'elementor_data_json' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) use ( $clear_elementor_cache ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $post = get_post( $page_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Page not found.' ];
              }

              $elementor_data_json = (string) $input['elementor_data_json'];
              $decoded = json_decode( $elementor_data_json, true );
              if ( JSON_ERROR_NONE !== json_last_error() || ! is_array( $decoded ) ) {
                return [ 'success' => false, 'error' => 'Invalid elementor_data_json payload.' ];
              }

              $update_payload = [ 'ID' => $page_id ];
              if ( ! empty( $input['title'] ) ) {
                $update_payload['post_title'] = sanitize_text_field( (string) $input['title'] );
              }
              if ( ! empty( $input['status'] ) ) {
                $update_payload['post_status'] = (string) $input['status'];
              }

              if ( count( $update_payload ) > 1 ) {
                $update_result = wp_update_post( $update_payload, true );
                if ( is_wp_error( $update_result ) ) {
                  return [ 'success' => false, 'error' => $update_result->get_error_message() ];
                }
              }

              update_post_meta( $page_id, '_elementor_data', wp_slash( $elementor_data_json ) );
              update_post_meta( $page_id, '_elementor_edit_mode', 'builder' );
              update_post_meta( $page_id, '_elementor_template_type', 'wp-page' );
              update_post_meta( $page_id, '_elementor_version', defined( 'ELEMENTOR_VERSION' ) ? ELEMENTOR_VERSION : '3.35.3' );

              if ( ! empty( $input['page_settings_json'] ) ) {
                $page_settings = json_decode( (string) $input['page_settings_json'], true );
                if ( JSON_ERROR_NONE === json_last_error() && is_array( $page_settings ) ) {
                  update_post_meta( $page_id, '_elementor_page_settings', $page_settings );
                }
              }

              $clear_elementor_cache();

              return [
                'success' => true,
                'page_id' => $page_id,
                'url' => get_permalink( $page_id ),
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/update-elementor-page-settings',
            'Update Elementor Page Settings',
            'Set Elementor page-level settings via JSON payload.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
                'page_settings_json' => [ 'type' => 'string' ],
              ],
              'required' => [ 'page_id', 'page_settings_json' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) use ( $clear_elementor_cache ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $post = get_post( $page_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Page not found.' ];
              }

              $settings = json_decode( (string) $input['page_settings_json'], true );
              if ( JSON_ERROR_NONE !== json_last_error() || ! is_array( $settings ) ) {
                return [ 'success' => false, 'error' => 'Invalid page_settings_json payload.' ];
              }

              update_post_meta( $page_id, '_elementor_page_settings', $settings );
              $clear_elementor_cache();

              return [
                'success' => true,
                'page_id' => $page_id,
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/clear-elementor-cache',
            'Clear Elementor Cache',
            'Clear Elementor generated file caches.',
            [
              'type' => 'object',
              'additionalProperties' => false,
            ],
            static function () use ( $clear_elementor_cache ) {
              $clear_elementor_cache();
              return [ 'success' => true ];
            },
            $manage_permission
          );

          $register_ability(
            'land-of-memories/upload-media-from-url',
            'Upload Media From URL',
            'Download a remote asset into the WordPress media library.',
            [
              'type' => 'object',
              'properties' => [
                'url' => [ 'type' => 'string' ],
                'title' => [ 'type' => 'string' ],
                'alt' => [ 'type' => 'string' ],
                'caption' => [ 'type' => 'string' ],
                'description' => [ 'type' => 'string' ],
              ],
              'required' => [ 'url' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $url = esc_url_raw( (string) ( $input['url'] ?? "" ) );
              if ( "" === $url ) {
                return [ 'success' => false, 'error' => 'A valid URL is required.' ];
              }

              $parsed = wp_parse_url( $url );
              $scheme = $parsed['scheme'] ?? "";
              $host = strtolower( $parsed['host'] ?? "" );

              $is_localhost = in_array( $host, [ 'localhost', '127.0.0.1' ], true );
              if ( 'https' !== $scheme && ! $is_localhost ) {
                return [ 'success' => false, 'error' => 'Only HTTPS URLs are allowed unless host is localhost.' ];
              }

              require_once ABSPATH . 'wp-admin/includes/file.php';
              require_once ABSPATH . 'wp-admin/includes/media.php';
              require_once ABSPATH . 'wp-admin/includes/image.php';

              $tmp_file = download_url( $url, 30 );
              if ( is_wp_error( $tmp_file ) ) {
                return [ 'success' => false, 'error' => $tmp_file->get_error_message() ];
              }

              $filename = wp_basename( $parsed['path'] ?? 'asset.jpg' );
              $file_array = [
                'name' => $filename,
                'tmp_name' => $tmp_file,
              ];

              $attachment_id = media_handle_sideload( $file_array, 0, isset( $input['description'] ) ? (string) $input['description'] : "" );

              if ( is_wp_error( $attachment_id ) ) {
                @unlink( $tmp_file );
                return [ 'success' => false, 'error' => $attachment_id->get_error_message() ];
              }

              if ( ! empty( $input['title'] ) || ! empty( $input['caption'] ) || ! empty( $input['description'] ) ) {
                wp_update_post( [
                  'ID' => $attachment_id,
                  'post_title' => ! empty( $input['title'] ) ? sanitize_text_field( (string) $input['title'] ) : get_the_title( $attachment_id ),
                  'post_excerpt' => ! empty( $input['caption'] ) ? (string) $input['caption'] : "",
                  'post_content' => ! empty( $input['description'] ) ? (string) $input['description'] : "",
                ] );
              }

              if ( ! empty( $input['alt'] ) ) {
                update_post_meta( $attachment_id, '_wp_attachment_image_alt', sanitize_text_field( (string) $input['alt'] ) );
              }

              return [
                'success' => true,
                'attachment_id' => (int) $attachment_id,
                'url' => wp_get_attachment_url( $attachment_id ),
              ];
            },
            $upload_permission
          );

          $register_ability(
            'land-of-memories/list-media',
            'List Media',
            'List media assets in the WordPress media library.',
            [
              'type' => 'object',
              'properties' => [
                'search' => [ 'type' => 'string' ],
                'limit' => [ 'type' => 'integer', 'default' => 20 ],
              ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $limit = isset( $input['limit'] ) ? absint( $input['limit'] ) : 20;
              $limit = max( 1, min( 100, $limit ) );

              $args = [
                'post_type' => 'attachment',
                'post_status' => 'inherit',
                'numberposts' => $limit,
                'orderby' => 'date',
                'order' => 'DESC',
              ];

              if ( ! empty( $input['search'] ) ) {
                $args['s'] = sanitize_text_field( (string) $input['search'] );
              }

              $items = [];
              $attachments = get_posts( $args );

              foreach ( $attachments as $attachment ) {
                $items[] = [
                  'id' => (int) $attachment->ID,
                  'title' => $attachment->post_title,
                  'url' => wp_get_attachment_url( $attachment->ID ),
                  'mime_type' => get_post_mime_type( $attachment->ID ),
                  'alt' => get_post_meta( $attachment->ID, '_wp_attachment_image_alt', true ),
                ];
              }

              return [
                'success' => true,
                'count' => count( $items ),
                'items' => $items,
              ];
            },
            $read_permission
          );

          $register_ability(
            'land-of-memories/set-featured-image',
            'Set Featured Image',
            'Assign a media attachment as featured image for a page.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
                'media_id' => [ 'type' => 'integer' ],
              ],
              'required' => [ 'page_id', 'media_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $media_id = absint( $input['media_id'] ?? 0 );

              $post = get_post( $page_id );
              $media = get_post( $media_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Page not found.' ];
              }

              if ( ! $media || 'attachment' !== $media->post_type ) {
                return [ 'success' => false, 'error' => 'Media attachment not found.' ];
              }

              set_post_thumbnail( $page_id, $media_id );

              return [
                'success' => true,
                'page_id' => $page_id,
                'media_id' => $media_id,
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/set-site-title-tagline',
            'Set Site Title and Tagline',
            'Update site title and tagline options.',
            [
              'type' => 'object',
              'properties' => [
                'title' => [ 'type' => 'string' ],
                'tagline' => [ 'type' => 'string' ],
              ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              if ( array_key_exists( 'title', $input ) ) {
                update_option( 'blogname', sanitize_text_field( (string) $input['title'] ) );
              }

              if ( array_key_exists( 'tagline', $input ) ) {
                update_option( 'blogdescription', sanitize_text_field( (string) $input['tagline'] ) );
              }

              return [
                'success' => true,
                'title' => get_option( 'blogname' ),
                'tagline' => get_option( 'blogdescription' ),
              ];
            },
            $manage_permission
          );

          $register_ability(
            'land-of-memories/set-custom-css',
            'Set Custom CSS',
            'Set global custom CSS in the active theme custom CSS post.',
            [
              'type' => 'object',
              'properties' => [
                'css' => [ 'type' => 'string' ],
              ],
              'required' => [ 'css' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              if ( ! function_exists( 'wp_update_custom_css_post' ) ) {
                return [ 'success' => false, 'error' => 'Custom CSS API is not available.' ];
              }

              $result = wp_update_custom_css_post( (string) $input['css'] );

              if ( is_wp_error( $result ) ) {
                return [ 'success' => false, 'error' => $result->get_error_message() ];
              }

              return [
                'success' => true,
                'css_post_id' => isset( $result->ID ) ? (int) $result->ID : 0,
              ];
            },
            $manage_permission
          );

          $register_ability(
            'land-of-memories/snapshot-page-state',
            'Snapshot Page State',
            'Capture a page snapshot (content + key meta) for safe rollback.',
            [
              'type' => 'object',
              'properties' => [
                'page_id' => [ 'type' => 'integer' ],
              ],
              'required' => [ 'page_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) {
              $page_id = absint( $input['page_id'] ?? 0 );
              $post = get_post( $page_id );

              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Page not found.' ];
              }

              $snapshots = get_option( 'lom_mcp_snapshots', [] );
              if ( ! is_array( $snapshots ) ) {
                $snapshots = [];
              }

              $snapshot_id = wp_generate_uuid4();
              $snapshots[ $snapshot_id ] = [
                'created_at' => gmdate( DATE_ATOM ),
                'page_id' => $page_id,
                'post' => [
                  'post_title' => $post->post_title,
                  'post_content' => $post->post_content,
                  'post_excerpt' => $post->post_excerpt,
                  'post_status' => $post->post_status,
                  'post_parent' => (int) $post->post_parent,
                  'menu_order' => (int) $post->menu_order,
                  'post_name' => $post->post_name,
                ],
                'meta' => [
                  '_elementor_data' => get_post_meta( $page_id, '_elementor_data', true ),
                  '_elementor_page_settings' => get_post_meta( $page_id, '_elementor_page_settings', true ),
                  '_elementor_edit_mode' => get_post_meta( $page_id, '_elementor_edit_mode', true ),
                  '_elementor_template_type' => get_post_meta( $page_id, '_elementor_template_type', true ),
                  '_wp_page_template' => get_post_meta( $page_id, '_wp_page_template', true ),
                  '_thumbnail_id' => get_post_meta( $page_id, '_thumbnail_id', true ),
                ],
              ];

              if ( count( $snapshots ) > 25 ) {
                $snapshots = array_slice( $snapshots, -25, null, true );
              }

              update_option( 'lom_mcp_snapshots', $snapshots, false );

              return [
                'success' => true,
                'snapshot_id' => $snapshot_id,
                'page_id' => $page_id,
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/restore-page-state',
            'Restore Page State',
            'Restore a previously captured snapshot for a page.',
            [
              'type' => 'object',
              'properties' => [
                'snapshot_id' => [ 'type' => 'string' ],
                'target_page_id' => [ 'type' => 'integer' ],
              ],
              'required' => [ 'snapshot_id' ],
              'additionalProperties' => false,
            ],
            static function ( $input ) use ( $clear_elementor_cache ) {
              $snapshot_id = sanitize_text_field( (string) ( $input['snapshot_id'] ?? "" ) );
              if ( "" === $snapshot_id ) {
                return [ 'success' => false, 'error' => 'snapshot_id is required.' ];
              }

              $snapshots = get_option( 'lom_mcp_snapshots', [] );
              if ( ! is_array( $snapshots ) || empty( $snapshots[ $snapshot_id ] ) ) {
                return [ 'success' => false, 'error' => 'Snapshot not found.' ];
              }

              $snapshot = $snapshots[ $snapshot_id ];
              $page_id = array_key_exists( 'target_page_id', $input )
                ? absint( $input['target_page_id'] )
                : absint( $snapshot['page_id'] ?? 0 );

              $post = get_post( $page_id );
              if ( ! $post || 'page' !== $post->post_type ) {
                return [ 'success' => false, 'error' => 'Target page not found.' ];
              }

              $post_data = $snapshot['post'] ?? [];
              $result = wp_update_post( [
                'ID' => $page_id,
                'post_title' => $post_data['post_title'] ?? $post->post_title,
                'post_content' => $post_data['post_content'] ?? $post->post_content,
                'post_excerpt' => $post_data['post_excerpt'] ?? $post->post_excerpt,
                'post_status' => $post_data['post_status'] ?? $post->post_status,
                'post_parent' => isset( $post_data['post_parent'] ) ? (int) $post_data['post_parent'] : (int) $post->post_parent,
                'menu_order' => isset( $post_data['menu_order'] ) ? (int) $post_data['menu_order'] : (int) $post->menu_order,
                'post_name' => isset( $post_data['post_name'] ) ? sanitize_title( (string) $post_data['post_name'] ) : $post->post_name,
              ], true );

              if ( is_wp_error( $result ) ) {
                return [ 'success' => false, 'error' => $result->get_error_message() ];
              }

              $meta = $snapshot['meta'] ?? [];
              $meta_keys = [
                '_elementor_data',
                '_elementor_page_settings',
                '_elementor_edit_mode',
                '_elementor_template_type',
                '_wp_page_template',
                '_thumbnail_id',
              ];

              foreach ( $meta_keys as $meta_key ) {
                if ( array_key_exists( $meta_key, $meta ) ) {
                  update_post_meta( $page_id, $meta_key, $meta[ $meta_key ] );
                }
              }

              $clear_elementor_cache();

              return [
                'success' => true,
                'snapshot_id' => $snapshot_id,
                'page_id' => $page_id,
                'url' => get_permalink( $page_id ),
              ];
            },
            $edit_permission
          );

          $register_ability(
            'land-of-memories/build-landing-page',
            'Build Landing Page',
            'Create or update a complete Land of Memories Elementor landing page and set it as homepage.',
            [
              'type' => 'object',
              'properties' => [
                'hero_image_url' => [ 'type' => 'string' ],
              ],
              'additionalProperties' => false,
            ],
            static function ( $input ) use ( $clear_elementor_cache ) {
              $hero_image = ! empty( $input['hero_image_url'] )
                ? esc_url_raw( (string) $input['hero_image_url'] )
                : 'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?auto=format&fit=crop&w=1800&q=80';

              $testimonials_html = '<div class="lom-testimonials-marquee">'
                . '<div class="lom-testimonials-col is-fast"><div class="lom-testimonials-track">'
                . '<article class="lom-memory-card"><p>"I still visit every week to write to my mum. It feels peaceful and close."</p><h5>Amelia R.</h5><span>Daughter</span></article>'
                . '<article class="lom-memory-card"><p>"Our whole family added stories from childhood in one evening. Beautifully simple."</p><h5>Noah T.</h5><span>Grandson</span></article>'
                . '<article class="lom-memory-card"><p>"The timeline helped us celebrate his life chapter by chapter."</p><h5>Sara M.</h5><span>Sister</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"I still visit every week to write to my mum. It feels peaceful and close."</p><h5>Amelia R.</h5><span>Daughter</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"Our whole family added stories from childhood in one evening. Beautifully simple."</p><h5>Noah T.</h5><span>Grandson</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"The timeline helped us celebrate his life chapter by chapter."</p><h5>Sara M.</h5><span>Sister</span></article>'
                . '</div></div>'
                . '<div class="lom-testimonials-col is-slow"><div class="lom-testimonials-track">'
                . '<article class="lom-memory-card"><p>"Friends from different countries could share memories in one place."</p><h5>Lucas P.</h5><span>Friend</span></article>'
                . '<article class="lom-memory-card"><p>"It gave us words when we had none."</p><h5>Elena K.</h5><span>Partner</span></article>'
                . '<article class="lom-memory-card"><p>"Simple, dignified, and easy to update whenever we miss her."</p><h5>Jason B.</h5><span>Brother</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"Friends from different countries could share memories in one place."</p><h5>Lucas P.</h5><span>Friend</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"It gave us words when we had none."</p><h5>Elena K.</h5><span>Partner</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"Simple, dignified, and easy to update whenever we miss her."</p><h5>Jason B.</h5><span>Brother</span></article>'
                . '</div></div>'
                . '<div class="lom-testimonials-col is-medium"><div class="lom-testimonials-track">'
                . '<article class="lom-memory-card"><p>"The photos and letters section became our shared family archive."</p><h5>Priya D.</h5><span>Niece</span></article>'
                . '<article class="lom-memory-card"><p>"The page feels warm and respectful, never overwhelming."</p><h5>Oliver W.</h5><span>Family Friend</span></article>'
                . '<article class="lom-memory-card"><p>"It helps us remember with love, not just sadness."</p><h5>Hannah C.</h5><span>Daughter</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"The photos and letters section became our shared family archive."</p><h5>Priya D.</h5><span>Niece</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"The page feels warm and respectful, never overwhelming."</p><h5>Oliver W.</h5><span>Family Friend</span></article>'
                . '<article class="lom-memory-card" aria-hidden="true"><p>"It helps us remember with love, not just sadness."</p><h5>Hannah C.</h5><span>Daughter</span></article>'
                . '</div></div>'
                . '</div>';

              $interactive_script = '<script>(function(){'
                . 'const revealEls=document.querySelectorAll(".lom-reveal");'
                . 'const hero=document.querySelector(".lom-hero");'
                . 'const heroImg=document.querySelector(".lom-parallax-image img");'
                . 'if(revealEls.length&&"IntersectionObserver" in window){'
                . 'const io=new IntersectionObserver((entries)=>{entries.forEach((entry)=>{if(entry.isIntersecting){entry.target.classList.add("is-visible");}});},{threshold:0.2,rootMargin:"0px 0px -8% 0px"});'
                . 'revealEls.forEach((el)=>io.observe(el));'
                . '}else{revealEls.forEach((el)=>el.classList.add("is-visible"));}'
                . 'let ticking=false;'
                . 'const paint=()=>{const y=window.scrollY||window.pageYOffset;'
                . 'if(hero&&heroImg){const h=hero.offsetHeight||1;const pct=Math.max(0,Math.min(1,y/h));hero.style.setProperty("--lom-hero-fade",(0.3+pct*0.55).toFixed(3));heroImg.style.transform="translate3d(0,"+(y*0.11).toFixed(1)+"px,0) scale("+(1.07-Math.min(y/7000,0.07)).toFixed(3)+")";}'
                . 'document.querySelectorAll(".lom-fade-parallax").forEach((el)=>{el.style.transform="translate3d(0,"+(y*0.04).toFixed(1)+"px,0)";});'
                . 'ticking=false;};'
                . 'window.addEventListener("scroll",()=>{if(!ticking){requestAnimationFrame(paint);ticking=true;}},{passive:true});paint();'
                . '})();</script>';

              $landing_css = <<<'CSS'
        @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500;600;700&family=Manrope:wght@400;500;600;700&display=swap');

        :root {
          --lom-ivory: #f7f2e9;
          --lom-sand: #efe3d1;
          --lom-teal: #2f6772;
          --lom-deep: #1f2f3f;
          --lom-gold: #b99a5c;
          --lom-rose: #b87a7e;
          --lom-card: rgba(255, 255, 255, 0.76);
        }

        body {
          font-family: 'Manrope', sans-serif;
          background: radial-gradient(120% 120% at 20% 0%, #fdfaf3 0%, #f8f4ec 35%, #f1ece2 100%);
          color: var(--lom-deep);
        }

        .site-main,
        .entry-content,
        .elementor,
        .elementor-section,
        .elementor-container,
        .e-con,
        .e-con-inner {
          max-width: none !important;
        }

        .elementor-widget-heading .elementor-heading-title,
        h1,
        h2,
        h3,
        h4 {
          font-family: 'Cormorant Garamond', serif;
          letter-spacing: 0.01em;
        }

        .lom-hero {
          --lom-hero-fade: 0.3;
          position: relative;
          min-height: 95vh;
          margin: 0 auto;
          padding: clamp(1.4rem, 4vw, 4.2rem);
          border-radius: 2rem;
          overflow: hidden;
          background:
            radial-gradient(100% 120% at 0% 0%, rgba(184, 122, 126, 0.24) 0%, rgba(184, 122, 126, 0) 55%),
            radial-gradient(100% 120% at 100% 100%, rgba(47, 103, 114, 0.24) 0%, rgba(47, 103, 114, 0) 55%),
            linear-gradient(145deg, #f9f6ef 0%, #f3ecdf 100%);
          box-shadow: 0 28px 75px rgba(31, 47, 63, 0.16);
        }

        .lom-hero > .e-con-inner {
          display: grid !important;
          grid-template-columns: minmax(320px, 0.95fr) minmax(340px, 1.05fr);
          align-items: center;
          gap: clamp(1.2rem, 2.8vw, 3rem);
          max-width: 1400px;
          margin: 0 auto;
        }

        .lom-hero::before {
          content: "";
          position: absolute;
          inset: 0;
          pointer-events: none;
          background: linear-gradient(180deg, rgba(31, 47, 63, calc(var(--lom-hero-fade) * 0.04)) 0%, rgba(31, 47, 63, calc(var(--lom-hero-fade) * 0.16)) 100%);
        }

        .lom-hero-title {
          font-size: clamp(3rem, 6.5vw, 6.1rem) !important;
          line-height: 0.92 !important;
          color: var(--lom-deep);
          margin-bottom: 0.8rem;
        }

        .lom-hero-subtitle {
          font-size: clamp(1.05rem, 1.9vw, 1.28rem);
          line-height: 1.78;
          max-width: 54ch;
          color: #364b5a;
        }

        .lom-hero-copy,
        .lom-hero-visual {
          position: relative;
          z-index: 1;
        }

        .lom-parallax-image img {
          width: 100%;
          height: clamp(460px, 72vh, 840px);
          object-fit: cover;
          border-radius: 1.6rem;
          box-shadow: 0 30px 80px rgba(31, 47, 63, 0.3);
          transform: translate3d(0, 0, 0) scale(1.07);
          transition: transform 0.2s linear;
          will-change: transform;
        }

        .lom-pill-btn .elementor-button {
          border-radius: 999px !important;
          padding: 0.95rem 1.65rem !important;
          border: 1px solid rgba(31, 47, 63, 0.14);
          box-shadow: 0 10px 22px rgba(31, 47, 63, 0.12);
        }

        .lom-section {
          margin-top: clamp(2.4rem, 5vw, 5rem);
          padding: clamp(1.5rem, 3vw, 3rem);
          border-radius: 1.6rem;
          background: linear-gradient(180deg, rgba(255, 255, 255, 0.84) 0%, rgba(255, 255, 255, 0.7) 100%);
          border: 1px solid rgba(31, 47, 63, 0.08);
          box-shadow: 0 16px 40px rgba(31, 47, 63, 0.08);
        }

        .lom-step-grid > .e-con-inner {
          display: grid !important;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: 1.25rem;
        }

        .lom-step-card {
          border-radius: 1.1rem;
          background: var(--lom-card);
          border: 1px solid rgba(31, 47, 63, 0.08);
          padding: 1.15rem;
        }

        .lom-testimonials-marquee {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: 1rem;
          max-height: 460px;
          overflow: hidden;
        }

        .lom-testimonials-col {
          overflow: hidden;
        }

        .lom-testimonials-track {
          display: flex;
          flex-direction: column;
          gap: 1rem;
          animation: lomColumn 20s linear infinite;
          will-change: transform;
        }

        .lom-testimonials-col.is-fast .lom-testimonials-track { animation-duration: 16s; }
        .lom-testimonials-col.is-medium .lom-testimonials-track { animation-duration: 22s; }
        .lom-testimonials-col.is-slow .lom-testimonials-track { animation-duration: 24s; animation-direction: reverse; }

        .lom-memory-card {
          background: var(--lom-card);
          border: 1px solid rgba(31, 47, 63, 0.12);
          border-radius: 1rem;
          padding: 1rem 1.05rem;
          box-shadow: 0 12px 26px rgba(31, 47, 63, 0.08);
        }

        .lom-memory-card p {
          margin: 0 0 0.85rem;
          line-height: 1.65;
        }

        .lom-memory-card h5 {
          margin: 0;
          font-size: 1rem;
          color: var(--lom-teal);
        }

        .lom-memory-card span {
          display: block;
          margin-top: 0.2rem;
          font-size: 0.88rem;
          opacity: 0.74;
        }

        .lom-editor-board {
          display: grid;
          grid-template-columns: repeat(4, minmax(0, 1fr));
          gap: 0.75rem;
        }

        .lom-editor-chip {
          border-radius: 999px;
          padding: 0.55rem 0.9rem;
          text-align: center;
          font-size: 0.86rem;
          background: rgba(47, 103, 114, 0.12);
          border: 1px solid rgba(47, 103, 114, 0.24);
        }

        .lom-reveal {
          opacity: 0;
          transform: translateY(32px);
          transition: opacity 0.8s ease, transform 0.8s ease;
        }

        .lom-reveal.is-visible {
          opacity: 1;
          transform: translateY(0);
        }

        @keyframes lomColumn {
          0% { transform: translateY(0); }
          100% { transform: translateY(-50%); }
        }

        @media (max-width: 1024px) {
          .lom-hero {
            min-height: auto;
            gap: 1.3rem;
            padding: 1.35rem;
          }

          .lom-hero > .e-con-inner {
            grid-template-columns: 1fr;
          }

          .lom-parallax-image img {
            height: clamp(300px, 48vh, 500px);
          }

          .lom-step-grid > .e-con-inner {
            grid-template-columns: 1fr;
          }

          .lom-testimonials-marquee {
            grid-template-columns: 1fr;
            max-height: none;
          }

          .lom-testimonials-track {
            animation: none;
          }

          .lom-editor-board {
            grid-template-columns: 1fr 1fr;
          }
        }

        @media (prefers-reduced-motion: reduce) {
          .lom-testimonials-col,
          .lom-testimonials-track,
          .lom-reveal,
          .lom-parallax-image img {
            animation: none !important;
            transition: none !important;
            transform: none !important;
          }
        }
        CSS;

              if ( function_exists( 'wp_update_custom_css_post' ) ) {
                wp_update_custom_css_post( $landing_css );
              }

              $elementor_data = [
                [
                  'id' => 'lomhero1',
                  'elType' => 'container',
                  'isInner' => false,
          'settings' => [
            'css_classes' => 'lom-hero lom-reveal',
          ],
                  'elements' => [
                    [
                      'id' => 'lomcopy1',
                      'elType' => 'container',
                      'isInner' => true,
              'settings' => [
                'css_classes' => 'lom-hero-copy',
              ],
                      'elements' => [
                        [
                          'id' => 'lomhed01',
                          'elType' => 'widget',
                          'widgetType' => 'heading',
                          'settings' => [
                            'title' => 'Land of Memories',
                            'size' => 'xxl',
                            '_css_classes' => 'lom-hero-title',
                          ],
                          'elements' => [],
                        ],
                        [
                          'id' => 'lomtxt01',
                          'elType' => 'widget',
                          'widgetType' => 'text-editor',
                          'settings' => [
                            'editor' => '<p class="lom-hero-subtitle">A gentle place to remember loved ones, gather stories, and keep their presence alive through shared memories.</p>',
                          ],
                          'elements' => [],
                        ],
                        [
                          'id' => 'lomcta01',
                          'elType' => 'widget',
                          'widgetType' => 'button',
                          'settings' => [
                            'text' => 'Create a Memorial Book',
                            'link' => [ 'url' => '#memorial-editor' ],
                            '_css_classes' => 'lom-pill-btn',
                            'button_background_color' => '#2f6772',
                            'button_text_color' => '#ffffff',
                          ],
                          'elements' => [],
                        ],
                        [
                          'id' => 'lomcta02',
                          'elType' => 'widget',
                          'widgetType' => 'button',
                          'settings' => [
                            'text' => 'Browse Memorials',
                            'link' => [ 'url' => '#featured-memorials' ],
                            '_css_classes' => 'lom-pill-btn',
                            'button_background_color' => '#f7f2e9',
                            'button_text_color' => '#1f2f3f',
                          ],
                          'elements' => [],
                        ],
                      ],
                    ],
                    [
                      'id' => 'lomvis01',
                      'elType' => 'container',
                      'isInner' => true,
              'settings' => [
                'css_classes' => 'lom-hero-visual lom-fade-parallax',
              ],
                      'elements' => [
                        [
                          'id' => 'lomimg01',
                          'elType' => 'widget',
                          'widgetType' => 'image',
                          'settings' => [
                            'image' => [
                              'url' => $hero_image,
                              'id' => 0,
                            ],
                            'size' => 'full',
                            '_css_classes' => 'lom-parallax-image',
                          ],
                          'elements' => [],
                        ],
                      ],
                    ],
                  ],
                ],
                [
                  'id' => 'lomsec01',
                  'elType' => 'container',
                  'isInner' => false,
          'settings' => [
            'css_classes' => 'lom-section lom-reveal',
          ],
                  'elements' => [
                    [
                      'id' => 'lomhed02',
                      'elType' => 'widget',
                      'widgetType' => 'heading',
                      'settings' => [
                        'title' => 'How Land of Memories Works',
                        'size' => 'xl',
                      ],
                      'elements' => [],
                    ],
                    [
                      'id' => 'lomstp01',
                      'elType' => 'container',
                      'isInner' => true,
              'settings' => [
                'css_classes' => 'lom-step-grid',
              ],
                      'elements' => [
                        [
                          'id' => 'lomico1',
                          'elType' => 'widget',
                          'widgetType' => 'icon-box',
                          'settings' => [
                            'selected_icon' => [ 'value' => 'fas fa-book-open', 'library' => 'fa-solid' ],
                            'title_text' => 'Create',
                            'description_text' => 'Start a memorial book with photos, life milestones, and heartfelt letters.',
                            '_css_classes' => 'lom-step-card',
                          ],
                          'elements' => [],
                        ],
                        [
                          'id' => 'lomico2',
                          'elType' => 'widget',
                          'widgetType' => 'icon-box',
                          'settings' => [
                            'selected_icon' => [ 'value' => 'fas fa-share-alt', 'library' => 'fa-solid' ],
                            'title_text' => 'Share',
                            'description_text' => 'Send one private or public link so family and friends can visit with ease.',
                            '_css_classes' => 'lom-step-card',
                          ],
                          'elements' => [],
                        ],
                        [
                          'id' => 'lomico3',
                          'elType' => 'widget',
                          'widgetType' => 'icon-box',
                          'settings' => [
                            'selected_icon' => [ 'value' => 'fas fa-heart', 'library' => 'fa-solid' ],
                            'title_text' => 'Remember Together',
                            'description_text' => 'Collect memories over time in one calm and lasting digital space.',
                            '_css_classes' => 'lom-step-card',
                          ],
                          'elements' => [],
                        ],
                      ],
                    ],
                  ],
                ],
                [
                  'id' => 'lomsec02',
                  'elType' => 'container',
                  'isInner' => false,
          'settings' => [
            'css_classes' => 'lom-section lom-reveal',
          ],
                  'elements' => [
                    [
                      'id' => 'lomhed03',
                      'elType' => 'widget',
                      'widgetType' => 'heading',
                      'settings' => [
                        'title' => 'Memorial Book Editor',
                        'size' => 'xl',
                        'html_tag' => 'h2',
                      ],
                      'elements' => [],
                    ],
                    [
                      'id' => 'lomtxt02',
                      'elType' => 'widget',
                      'widgetType' => 'text-editor',
                      'settings' => [
                        'editor' => '<p id="memorial-editor">A guided editor designed for non-technical families. Add chapters, gallery images, timeline moments, letters, and a living memory wall in minutes.</p>',
                      ],
                      'elements' => [],
                    ],
                    [
                      'id' => 'lomhtm01',
                      'elType' => 'widget',
                      'widgetType' => 'html',
                      'settings' => [
                        'html' => '<div class="lom-editor-board"><div class="lom-editor-chip">Life Story</div><div class="lom-editor-chip">Timeline</div><div class="lom-editor-chip">Gallery</div><div class="lom-editor-chip">Letters</div><div class="lom-editor-chip">Memories Wall</div><div class="lom-editor-chip">Privacy</div><div class="lom-editor-chip">Share Link</div><div class="lom-editor-chip">Print View</div></div>',
                      ],
                      'elements' => [],
                    ],
                  ],
                ],
                [
                  'id' => 'lomsec03',
                  'elType' => 'container',
                  'isInner' => false,
          'settings' => [
            'css_classes' => 'lom-section lom-reveal',
          ],
                  'elements' => [
                    [
                      'id' => 'lomhed04',
                      'elType' => 'widget',
                      'widgetType' => 'heading',
                      'settings' => [
                        'title' => 'Living Tributes From Families',
                        'size' => 'xl',
                      ],
                      'elements' => [],
                    ],
                    [
                      'id' => 'lomhtm02',
                      'elType' => 'widget',
                      'widgetType' => 'html',
                      'settings' => [
                        'html' => $testimonials_html,
                      ],
                      'elements' => [],
                    ],
                  ],
                ],
                [
                  'id' => 'lomsec04',
                  'elType' => 'container',
                  'isInner' => false,
          'settings' => [
            'css_classes' => 'lom-section lom-reveal',
          ],
                  'elements' => [
                    [
                      'id' => 'lomhed05',
                      'elType' => 'widget',
                      'widgetType' => 'heading',
                      'settings' => [
                        'title' => 'Ready to build a memorial book?',
                        'size' => 'xl',
                        'html_tag' => 'h2',
                      ],
                      'elements' => [],
                    ],
                    [
                      'id' => 'lomtxt03',
                      'elType' => 'widget',
                      'widgetType' => 'text-editor',
                      'settings' => [
                        'editor' => '<p id="featured-memorials">Create a respectful, shareable place where stories continue. Invite family and friends to add memories at their own pace.</p>',
                      ],
                      'elements' => [],
                    ],
                    [
                      'id' => 'lomcta03',
                      'elType' => 'widget',
                      'widgetType' => 'button',
                      'settings' => [
                        'text' => 'Start Now',
                        'link' => [ 'url' => '#memorial-editor' ],
                        '_css_classes' => 'lom-pill-btn',
                        'button_background_color' => '#1f2f3f',
                        'button_text_color' => '#ffffff',
                      ],
                      'elements' => [],
                    ],
                    [
                      'id' => 'lomhtm03',
                      'elType' => 'widget',
                      'widgetType' => 'html',
                      'settings' => [
                        'html' => $interactive_script,
                      ],
                      'elements' => [],
                    ],
                  ],
                ],
              ];

              $page = get_page_by_path( 'land-of-memories', OBJECT, 'page' );

              if ( $page instanceof WP_Post ) {
                $page_id = (int) $page->ID;
              } else {
                $page_id = wp_insert_post( [
                  'post_type' => 'page',
                  'post_title' => 'Land of Memories',
                  'post_name' => 'land-of-memories',
                  'post_status' => 'publish',
                ] );

                if ( is_wp_error( $page_id ) ) {
                  return [ 'success' => false, 'error' => $page_id->get_error_message() ];
                }
              }

              $update_result = wp_update_post( [
                'ID' => $page_id,
                'post_status' => 'publish',
                'post_content' => "",
              ], true );

              if ( is_wp_error( $update_result ) ) {
                return [ 'success' => false, 'error' => $update_result->get_error_message() ];
              }

              update_post_meta( $page_id, '_elementor_data', wp_slash( wp_json_encode( $elementor_data ) ) );
              update_post_meta( $page_id, '_elementor_edit_mode', 'builder' );
              update_post_meta( $page_id, '_elementor_template_type', 'wp-page' );
              update_post_meta( $page_id, '_elementor_version', defined( 'ELEMENTOR_VERSION' ) ? ELEMENTOR_VERSION : '3.35.3' );
              update_post_meta( $page_id, '_elementor_page_settings', [
                'page_layout' => 'elementor_full_width',
              ] );
              update_post_meta( $page_id, '_wp_page_template', 'elementor_canvas' );

              update_option( 'show_on_front', 'page' );
              update_option( 'page_on_front', $page_id );

              $clear_elementor_cache();

              return [
                'success' => true,
                'page_id' => $page_id,
                'url' => get_permalink( $page_id ),
              ];
            },
            $manage_permission
          );
    };

    if ( did_action( 'wp_abilities_api_init' ) ) {
      $lom_register_abilities();
    } else {
      add_action( 'wp_abilities_api_init', $lom_register_abilities );
    }
    PHP
  '';
in
{
  services.wordpress = {
    webserver = "nginx";
    sites."localhost" = {
      database.createLocally = true;
      plugins = {
        inherit buddypress elementor;
        "abilities-api" = abilitiesApi;
        "mcp-adapter" = mcpAdapter;
        "land-of-memories-mcp" = landOfMemoriesMcp;
      };
      settings = {
        WP_ENVIRONMENT_TYPE = "local";
      };
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
